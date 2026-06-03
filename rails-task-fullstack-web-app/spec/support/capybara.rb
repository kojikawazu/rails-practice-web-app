require "capybara/rails"
require "capybara/rspec"

# selenium は実ブラウザ往復でレイテンシが大きいため、待機時間を延ばして
# 連続実行時の取りこぼし（false negative）を防ぐ。rack_test には影響しない。
Capybara.default_max_wait_time = 5

RSpec.configure do |config|
  # 既定: 確認画面フロー等はサーバー往復（JS 非依存）のため、実ブラウザ不要の
  # rack_test ドライバで駆動する。高速・安定。
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  # JS 必須の挙動（Turbo の turbo_confirm 等）は :js タグを付けた spec のみ
  # headless Chrome（selenium）で駆動する。selenium-webdriver の Selenium Manager が
  # 対応する chromedriver を自動取得する。
  config.before(:each, type: :system, js: true) do
    driven_by :selenium, using: :headless_chrome
  end

  # 通常の `rspec` 実行では JS テストを除外し、Chrome 不要・高速を維持する。
  # 実行するときは `rspec --tag js`（または CI）で明示的に指定する。
  config.filter_run_excluding js: true
end
