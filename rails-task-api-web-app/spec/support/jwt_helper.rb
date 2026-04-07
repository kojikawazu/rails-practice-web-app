module JwtHelper
  def auth_headers(user)
    token = JsonWebToken.encode(user_id: user.id)
    { "Authorization" => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include JwtHelper, type: :request
end
