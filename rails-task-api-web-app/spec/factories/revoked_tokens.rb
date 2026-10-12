FactoryBot.define do
  factory :revoked_token do
    jti { SecureRandom.uuid }
    expires_at { 24.hours.from_now }

    trait :expired do
      expires_at { 1.minute.ago }
    end
  end
end
