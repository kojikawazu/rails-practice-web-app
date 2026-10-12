require "rails_helper"

RSpec.describe RevokedToken, type: :model do
  describe "バリデーション" do
    subject { build(:revoked_token) }

    it { is_expected.to validate_presence_of(:jti) }
    it { is_expected.to validate_uniqueness_of(:jti) }
    it { is_expected.to validate_presence_of(:expires_at) }
  end

  describe ".expired" do
    it "有効期限を過ぎた行だけを返す（期限切れのトークンは JWT の検証で弾かれるため、記録を残す意味が無い）" do
      expired = create(:revoked_token, :expired)
      active = create(:revoked_token)

      expect(described_class.expired).to contain_exactly(expired)
      expect(described_class.expired).not_to include(active)
    end
  end
end
