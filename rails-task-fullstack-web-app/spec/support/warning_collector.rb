# RSpec 実行中に出た Ruby / gem の警告を記録し、1 件でもあればスイートを失敗させる。
# 警告は出ていても green のまま気づかれない（#135 の Rack 非推奨警告）。
# 「警告ゼロを維持する」（.claude/rules/static-analysis.md）を CI で担保するための仕組み。
#
# - 対象は Kernel#warn 経由の警告（Kernel#warn は Warning.warn を呼ぶ）。
#   Rails の非推奨警告は Warning.warn を通らず $stderr へ直接出るため、
#   config/environments/test.rb の active_support.deprecation = :raise で別途落とす。
# - 警告の場では例外にしない。Capybara のサーバースレッドなどで発生すると、
#   原因の分かりにくい 500 や別の失敗に化けるため。出力は残し、最後にまとめて落とす。
module WarningCollector
  @warnings = []
  @mutex = Mutex.new

  # @param message [String] 警告本文
  # @return [void]
  def self.record(message)
    @mutex.synchronize { @warnings << message }
  end

  # @return [Array<String>] 記録した警告（重複を除く）
  def self.warnings
    @mutex.synchronize { @warnings.uniq }
  end

  # Warning.warn を横取りして記録し、本来の出力（super）はそのまま行う。
  module Hook
    def warn(message, *args, **kwargs)
      WarningCollector.record(message)
      super
    end
  end
end

Warning.extend(WarningCollector::Hook)

RSpec.configure do |config|
  config.after(:suite) do
    warnings = WarningCollector.warnings
    next if warnings.empty?

    raise "RSpec の実行中に警告が #{warnings.size} 種類出ました（警告ゼロを維持する）:\n#{warnings.join}"
  end
end
