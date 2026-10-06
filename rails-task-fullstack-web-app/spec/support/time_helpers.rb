# 時刻依存の振る舞い（signed_id の有効期限・古い blob の清掃など）を、待たずに検証するため
# travel_to / freeze_time を全 spec で使えるようにする（rspec-rails は既定で include しない）。
RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
end
