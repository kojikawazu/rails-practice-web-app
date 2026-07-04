require "rails_helper"

# AuthService.login は「認証の可否」という実ロジックを持つため UT の価値がある。
# I/O 境界の User.find_by だけを allow でスタブし DB を避ける。authenticate は
# instance_double 上でスタブする。signup / Project・Task の CRUD は UT を書かない
# （build/save/update の委譲＝実装追認になるため）。詳細は docs/08 のモック方針。
RSpec.describe AuthService do
  describe ".login" do
    let(:user) { instance_double(User, id: 7) }

    it "正しい資格情報なら該当ユーザーを返す" do
      allow(User).to receive(:find_by).with(email: "a@example.com").and_return(user)
      allow(user).to receive(:authenticate).with("correct").and_return(true)

      expect(described_class.login(email: "a@example.com", password: "correct")).to eq(user)
    end

    it "パスワードが誤りなら nil を返す" do
      allow(User).to receive(:find_by).with(email: "a@example.com").and_return(user)
      allow(user).to receive(:authenticate).with("wrong").and_return(false)

      expect(described_class.login(email: "a@example.com", password: "wrong")).to be_nil
    end

    it "メールが存在しない場合も nil を返す（列挙攻撃対策で誤り時と同じ結果）" do
      allow(User).to receive(:find_by).with(email: "missing@example.com").and_return(nil)

      expect(described_class.login(email: "missing@example.com", password: "x")).to be_nil
    end
  end
end
