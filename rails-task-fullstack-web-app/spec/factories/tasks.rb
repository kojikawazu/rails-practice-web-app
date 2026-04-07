FactoryBot.define do
  factory :task do
    title { Faker::Lorem.sentence(word_count: 4).chomp(".") }
    status { :not_started }
    due_date { Faker::Date.forward(days: 14) }
    association :project
  end
end
