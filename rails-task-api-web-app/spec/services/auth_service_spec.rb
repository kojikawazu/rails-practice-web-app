require "rails_helper"

# AuthService.login は「認証の可否」という実ロジックを持つため UT の価値がある。
# DB を避けるため User.find_by だけを allow でスタブし、JsonWebToken は実物を動かして
# 「本物の decode 可能なトークン」を検証する（スタブした定数の照合にはしない）。
#
# signup は分岐が save 成否のみでモックすると実装追認になるため、ここでは UT を書かず
# request spec（IT）とシナリオで担保する（docs/08 のモック方針を参照）。
#
# authenticate も同じ方針で、DB 境界（User.find_by / RevokedToken.exists?）だけをスタブし、
# JWT の検証は実物で動かす。logout は失効の記録と期限切れの掃除という DB 操作への委譲のため
# モックの UT を書かず、request spec とシナリオで実 DB の結果を検証する。HTTP 経由で再現できない
# 同時ログアウトの競合だけは、下の describe で実 DB を使って直接呼ぶ。
RSpec.describe AuthService do
  describe ".authenticate" do
    let(:user) { instance_double(User, id: 7) }

    # JsonWebToken.encode は必ず jti を入れるため、jti / exp を欠いた「変更前に発行された形」の
    # トークンは JWT ライブラリで直接署名して作る（署名自体は正しく、欠けているのはクレームだけ）。
    def sign(payload)
      JWT.encode(payload, Rails.application.secret_key_base)
    end

    it "有効で失効していないトークンなら成功し、ユーザーとクレームを返す" do
      token = JsonWebToken.encode(user_id: 7)
      jti = JsonWebToken.decode(token)[:jti]
      allow(User).to receive(:find_by).with(id: 7).and_return(user)
      allow(RevokedToken).to receive(:exists?).with(jti: jti).and_return(false)

      result = described_class.authenticate(token)

      expect(result).to be_success
      expect(result.data[:user]).to eq(user)
      expect(result.data[:claims][:jti]).to eq(jti)
    end

    it "ログアウトで失効したトークンは、署名と有効期限が正しくても unauthorized で失敗する" do
      token = JsonWebToken.encode(user_id: 7)
      allow(User).to receive(:find_by).with(id: 7).and_return(user)
      allow(RevokedToken).to receive(:exists?).and_return(true)

      result = described_class.authenticate(token)

      expect(result).to be_failure
      expect(result.code).to eq(:unauthorized)
    end

    it "jti を持たないトークンは、失効させられないため unauthorized で失敗する" do
      token = sign(user_id: 7, exp: 1.hour.from_now.to_i)
      allow(User).to receive(:find_by).with(id: 7).and_return(user)

      result = described_class.authenticate(token)

      expect(result).to be_failure
      expect(result.code).to eq(:unauthorized)
    end

    it "exp を持たないトークンは、失効の記録期限を決められないため unauthorized で失敗する" do
      token = sign(user_id: 7, jti: SecureRandom.uuid)
      allow(User).to receive(:find_by).with(id: 7).and_return(user)
      allow(RevokedToken).to receive(:exists?).and_return(false)

      result = described_class.authenticate(token)

      expect(result).to be_failure
      expect(result.code).to eq(:unauthorized)
    end

    it "トークンのユーザーが存在しなければ unauthorized で失敗する" do
      token = JsonWebToken.encode(user_id: 7)
      allow(User).to receive(:find_by).with(id: 7).and_return(nil)
      allow(RevokedToken).to receive(:exists?).and_return(false)

      result = described_class.authenticate(token)

      expect(result).to be_failure
      expect(result.code).to eq(:unauthorized)
    end

    it "トークンが無い・検証できない場合は unauthorized で失敗する" do
      expect(described_class.authenticate(nil).code).to eq(:unauthorized)
      expect(described_class.authenticate("not-a-jwt").code).to eq(:unauthorized)
    end
  end

  # 同じトークンで同時にログアウトされると、どちらも authenticate を通過した後で記録が衝突する。
  # HTTP 経由では 2 回目が authenticate で 401 になり再現できないため、既に記録がある状態で直接呼ぶ。
  # 記録の有無という DB の結果そのものを見るので、ここは実 DB で動かす（モックすると実装追認になる）。
  describe ".logout（同時ログアウトの競合）" do
    it "同じ jti の記録が既にあっても例外にせず成功し、記録を重複させない" do
      claims = JsonWebToken.decode(JsonWebToken.encode(user_id: 7))
      create(:revoked_token, jti: claims[:jti], expires_at: Time.zone.at(claims[:exp]))

      result = described_class.logout(claims)

      expect(result).to be_success
      expect(result.status).to eq(:no_content)
      expect(RevokedToken.where(jti: claims[:jti]).count).to eq(1)
    end
  end

  describe ".login" do
    let(:user) { instance_double(User, id: 7) }

    it "正しい資格情報なら成功し、token に user_id が入る" do
      allow(User).to receive(:find_by).with(email: "a@example.com").and_return(user)
      allow(user).to receive(:authenticate).with("correct").and_return(true)

      result = described_class.login(email: "a@example.com", password: "correct")

      expect(result).to be_success
      expect(result.status).to eq(:ok)
      expect(result.data[:user]).to eq(user)
      expect(JsonWebToken.decode(result.data[:token])[:user_id]).to eq(7)
    end

    it "パスワードが誤りなら token を返さず invalid_credentials で失敗する" do
      allow(User).to receive(:find_by).with(email: "a@example.com").and_return(user)
      allow(user).to receive(:authenticate).with("wrong").and_return(false)

      result = described_class.login(email: "a@example.com", password: "wrong")

      expect(result).to be_failure
      expect(result.code).to eq(:invalid_credentials)
      expect(result.data).to be_nil
    end

    it "メールが存在しない場合も、パスワード誤りと同じ失敗理由になる（列挙攻撃対策）" do
      allow(User).to receive(:find_by).with(email: "missing@example.com").and_return(nil)
      allow(User).to receive(:find_by).with(email: "a@example.com").and_return(user)
      allow(user).to receive(:authenticate).with("wrong").and_return(false)

      not_found = described_class.login(email: "missing@example.com", password: "x")
      wrong_pw  = described_class.login(email: "a@example.com", password: "wrong")

      expect(not_found).to be_failure
      expect(not_found.code).to eq(:invalid_credentials)
      expect(not_found.code).to eq(wrong_pw.code)
      expect(not_found.errors).to eq(wrong_pw.errors)
    end
  end
end
