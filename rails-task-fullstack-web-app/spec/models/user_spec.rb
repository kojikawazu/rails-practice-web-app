require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:projects).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(50) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email) }
    it { is_expected.to have_secure_password }

    it 'is invalid with a malformed email' do
      user = build(:user, email: 'not_an_email')
      expect(user).not_to be_valid
    end

    it 'is valid with a name of exactly 50 characters' do
      expect(build(:user, name: 'a' * 50)).to be_valid
    end

    it 'is invalid with a name of 51 characters' do
      expect(build(:user, name: 'a' * 51)).not_to be_valid
    end

    it 'is valid with a password of exactly 6 characters' do
      expect(build(:user, password: 'abcdef', password_confirmation: 'abcdef')).to be_valid
    end

    it 'is invalid with a password shorter than 6 characters on create' do
      user = build(:user, password: 'short', password_confirmation: 'short')
      expect(user).not_to be_valid
    end
  end

  describe '#authenticate' do
    let(:user) { create(:user, password: 'password123') }

    it 'returns user with correct password' do
      expect(user.authenticate('password123')).to eq(user)
    end

    it 'returns false with wrong password' do
      expect(user.authenticate('wrong')).to be_falsey
    end
  end
end
