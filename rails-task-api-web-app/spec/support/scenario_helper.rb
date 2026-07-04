# シナリオ／リクエストスペック用の小さなヘルパー。
# 既存の jwt_helper.rb と同じく type: :request に include する。
module ScenarioHelper
  # 直近レスポンスのボディを JSON としてパースする。
  #
  # @return [Hash, Array] パース結果
  def json
    JSON.parse(response.body)
  end

  # Bearer 認証ヘッダーを組み立てる。
  #
  # @param token [String] JWT
  # @return [Hash] `{ "Authorization" => "Bearer <token>" }`
  def bearer(token)
    { "Authorization" => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include ScenarioHelper, type: :request
end
