require 'rails_helper'

RSpec.describe Task, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(200) }

    it 'is invalid with an unknown status' do
      task = build(:task)
      task.status = 99
      expect(task).not_to be_valid
    end
  end

  describe 'enum status' do
    it 'defaults to not_started without factory' do
      # factory を使わず Task.new でモデル本来のデフォルトを検証する
      task = Task.new
      expect(task.not_started?).to be true
    end

    it 'can be set to in_progress' do
      task = build(:task, status: :in_progress)
      expect(task.in_progress?).to be true
    end

    it 'can be set to completed' do
      task = build(:task, status: :completed)
      expect(task.completed?).to be true
    end
  end
end
