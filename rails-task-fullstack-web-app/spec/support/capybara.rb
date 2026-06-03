require "capybara/rails"
require "capybara/rspec"

# 確認画面フローはすべてサーバー往復（ネイティブ HTML フォーム submit / formaction）で
# JS 非依存のため、実ブラウザ不要の rack_test ドライバで駆動する。高速・安定。
# JS 必須の挙動（削除の turbo_confirm 等）を検証する場合のみ :selenium を別途使う。
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end
end
