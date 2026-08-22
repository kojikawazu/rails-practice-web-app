FactoryBot.define do
  factory :task do
    title { Faker::Lorem.sentence(word_count: 4).chomp(".") }
    status { :not_started }
    due_date { Faker::Date.forward(days: 14) }
    association :project

    # 作成時は not_started 固定（Task の遷移規則）のため、途中状態のタスクは
    # 許可された遷移を踏んで作る。create(:task, status: :completed) は作成時の検証で弾かれる。
    # after(:create) のため build では適用されない点に注意する。
    trait :in_progress do
      after(:create) { |task| task.update!(status: :in_progress) }
    end

    trait :completed do
      after(:create) do |task|
        task.update!(status: :in_progress)
        task.update!(status: :completed)
      end
    end
  end
end
