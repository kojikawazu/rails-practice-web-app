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

  describe '.with_task_counts' do
    it 'exposes each project task count as tasks_count' do
      two_tasks = create(:project)
      three_tasks = create(:project)
      create_list(:task, 2, project: two_tasks)
      create_list(:task, 3, project: three_tasks)

      projects = described_class.with_task_counts.index_by(&:id)

      expect(projects[two_tasks.id].tasks_count).to eq(2)
      expect(projects[three_tasks.id].tasks_count).to eq(3)
    end

    it 'keeps a project that has no tasks (LEFT JOIN, not INNER JOIN)' do
      without_tasks = create(:project)

      projects = described_class.with_task_counts.index_by(&:id)

      expect(projects[without_tasks.id].tasks_count).to eq(0)
    end
  end
end
