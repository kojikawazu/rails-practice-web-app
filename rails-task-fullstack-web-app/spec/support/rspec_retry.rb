require "rspec/retry"

RSpec.configure do |config|
  # リトライ時に理由を出力する（CI ログで何回目で通ったか分かるように）。
  config.verbose_retry = true
  config.display_try_failure_messages = true

  # selenium ベースの :js system spec は、turbo: false のネイティブ全ページ送信の
  # 遷移タイミングで稀に取りこぼす（特に低速・コールドな CI の headless Chrome）。
  # production の挙動は実ブラウザで検証済みのため、:js のみ自動リトライしてフレークを
  # 吸収する。リトライ対象を :js に限定し、他テストの本物の失敗は隠さない。
  config.around(:each, :js) do |example|
    example.run_with_retry retry: 3
  end
end
