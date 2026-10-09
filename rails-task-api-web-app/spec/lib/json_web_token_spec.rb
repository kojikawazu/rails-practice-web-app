require "rails_helper"

# JsonWebToken は DB 非依存の純粋ロジックのため、モックを使わず実物の JWT ライブラリで
# 検証する（UT）。round-trip・有効期限・改ざん・不正入力という認証系全体のセキュリティ契約を固定する。
RSpec.describe JsonWebToken do
  describe ".encode / .decode の round-trip" do
    it "encode したペイロードを decode すると値が復元される" do
      token = described_class.encode(user_id: 42)
      expect(described_class.decode(token)[:user_id]).to eq(42)
    end

    it "文字列キーでも取り出せる（HashWithIndifferentAccess で返る）" do
      token = described_class.encode(user_id: 42)
      expect(described_class.decode(token)["user_id"]).to eq(42)
    end

    it "既定の有効期限は約24時間後に設定される" do
      token = described_class.encode(user_id: 1)
      expect(described_class.decode(token)[:exp]).to be_within(5).of(24.hours.from_now.to_i)
    end

    it "明示した有効期限を尊重する" do
      exp = 1.hour.from_now
      token = described_class.encode({ user_id: 1 }, exp)
      expect(described_class.decode(token)[:exp]).to eq(exp.to_i)
    end
  end

  describe ".decode の失敗系（例外を投げず nil を返す）" do
    it "有効期限切れのトークンは nil を返す" do
      token = described_class.encode({ user_id: 1 }, 1.hour.ago)
      expect(described_class.decode(token)).to be_nil
    end

    it "署名が改ざんされたトークンは nil を返す" do
      header, payload, = described_class.encode(user_id: 1).split(".")
      tampered = [ header, payload, "invalid-signature" ].join(".")
      expect(described_class.decode(tampered)).to be_nil
    end

    it "JWT 形式でない文字列は nil を返す" do
      expect(described_class.decode("not-a-jwt")).to be_nil
    end

    it "nil を渡しても nil を返す（例外を投げない）" do
      expect(described_class.decode(nil)).to be_nil
    end
  end

  # 署名鍵は環境ごとに変わる値（ruby.md「定数の配置」）のため、クラスロード時に固定せず
  # 呼び出しごとに参照する。鍵のローテーションを再現するため secret_key_base だけを差し替える。
  describe "署名鍵の参照タイミング" do
    it "secret_key_base をローテーションすると、旧鍵で発行したトークンは検証に失敗する" do
      token = described_class.encode(user_id: 1)
      allow(Rails.application).to receive(:secret_key_base).and_return(SecureRandom.hex(64))

      expect(described_class.decode(token)).to be_nil
    end

    it "ローテーション後の鍵で発行したトークンは検証に成功する" do
      allow(Rails.application).to receive(:secret_key_base).and_return(SecureRandom.hex(64))
      token = described_class.encode(user_id: 1)

      expect(described_class.decode(token)[:user_id]).to eq(1)
    end
  end
end
