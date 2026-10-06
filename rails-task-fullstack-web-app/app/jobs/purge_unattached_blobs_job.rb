# 確認フローで staging したまま放棄された（どのタスクにも添付されなかった）blob を清掃するジョブ。
# 画像は確認画面へ進んだ時点で blob 化されるため、フォームの放棄・離脱・保存失敗で未添付の blob が残る。
#
# このアプリでは未添付の blob は確認フローの staging でしか生まれない（direct upload は使わない）ため、
# 「未添付かつ保持期間を過ぎた blob」を放棄されたものとみなして purge する。
# 本番は config/recurring.yml（Solid Queue の定期実行）から日次で起動する。
class PurgeUnattachedBlobsJob < ApplicationJob
  queue_as :default

  # 未添付 blob を残す期間。確認中の blob を消さないよう、staging の signed_id の有効期限
  # （TaskImageService::STAGING_EXPIRES_IN = 1 時間）より十分長い 1 日とする。
  RETENTION = 1.day

  # 保持期間を過ぎた未添付 blob の削除を予約する（ストレージ上のファイルごと PurgeJob が消す）。
  #
  # @return [void]
  def perform
    ActiveStorage::Blob.unattached.where(created_at: ...RETENTION.ago).find_each(&:purge_later)
  end
end
