FactoryBot.define do
  factory :project do
    title { Faker::Lorem.sentence(word_count: 3).chomp(".") }
    description { Faker::Lorem.paragraph }
    association :user
  end
end
