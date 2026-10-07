# rate_limit のカウンタ（test 環境は memory_store）を例ごとに消し、前の例のリクエスト回数を持ち越さない。
# request spec の remote_ip は常に 127.0.0.1 のため、クリアしないと例の実行順で結果が変わる。
RSpec.configure do |config|
  config.before do
    Rails.cache.clear
  end
end
