require "rails_helper"

# AuthService.login は「認証の可否」という実ロジックを持つため UT の価値がある。
# DB を避けるため User.find_by だけを allow でスタブし、JsonWebToken は実物を動かして
# 「本物の decode 可能なトークン」を検証する（スタブした定数の照合にはしない）。
#
# signup は分岐が save 成否のみでモックすると実装追認になるため、ここでは UT を書かず
# request spec（IT）とシナリオで担保する（docs/08 のモック方針を参照）。
RSpec.describe AuthService do
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

    it "パスワードが誤りなら token を返さず 401 になる" do
      allow(User).to receive(:find_by).with(email: "a@example.com").and_return(user)
      allow(user).to receive(:authenticate).with("wrong").and_return(false)

      result = described_class.login(email: "a@example.com", password: "wrong")

      expect(result).to be_failure
      expect(result.status).to eq(:unauthorized)
      expect(result.data).to be_nil
    end

    it "メールが存在しない場合も 401 で、誤り時と同一メッセージ（列挙攻撃対策）" do
      allow(User).to receive(:find_by).with(email: "missing@example.com").and_return(nil)
      allow(User).to receive(:find_by).with(email: "a@example.com").and_return(user)
      allow(user).to receive(:authenticate).with("wrong").and_return(false)

      not_found = described_class.login(email: "missing@example.com", password: "x")
      wrong_pw  = described_class.login(email: "a@example.com", password: "wrong")

      expect(not_found).to be_failure
      expect(not_found.status).to eq(:unauthorized)
      expect(not_found.errors).to eq(wrong_pw.errors)
    end
  end
end
