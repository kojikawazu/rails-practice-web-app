FactoryBot.define do
  factory :task do
    title { Faker::Lorem.sentence(word_count: 4).chomp(".") }
    status { :not_started }
    start_date { Faker::Date.forward(days: 7) }
    end_date { start_date + 7 } # 終了日 >= 開始日 を満たす
    association :project
  end
end
