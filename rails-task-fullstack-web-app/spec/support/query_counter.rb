# ブロック内で発行された SQL の本数を数えるヘルパー。
# N+1（表示件数に比例してクエリが増える）の回帰を spec で固定するために使う。
module QueryCounter
  # ブロック内で発行された SQL のうち、パターンに一致するものを数える。
  #
  # スキーマ取得（SCHEMA）とトランザクション制御（TRANSACTION）は業務クエリではないため除外する。
  # クエリキャッシュにヒットした SQL は数に含める（キャッシュ任せで N+1 を見逃さないため）。
  #
  # @param pattern [Regexp] 数える対象の SQL 正規表現（例: /"tasks"/）
  # @return [Integer] 一致した SQL の本数
  def count_queries(pattern)
    count = 0
    subscriber = lambda do |_name, _started, _finished, _id, payload|
      next if %w[SCHEMA TRANSACTION].include?(payload[:name])

      count += 1 if payload[:sql].match?(pattern)
    end

    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { yield }
    count
  end
end

RSpec.configure do |config|
  config.include QueryCounter
end
