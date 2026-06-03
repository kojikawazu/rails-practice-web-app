require 'rails_helper'

RSpec.describe Project, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:tasks).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(100) }

    it 'is valid with a title of exactly 100 characters' do
      expect(build(:project, title: 'a' * 100)).to be_valid
    end

    it 'is invalid with a title of 101 characters' do
      expect(build(:project, title: 'a' * 101)).not_to be_valid
    end
  end
end
