require "rails_helper"

# 確認フローで staging したまま放棄された blob の清掃を、実 blob（Disk サービス）で検証する。
# purge_later が積む ActiveStorage::PurgeJob を perform_enqueued_jobs で実行し、実際に消えることまで見る。
RSpec.describe PurgeUnattachedBlobsJob do
  include ActiveJob::TestHelper

  let(:task) { create(:task) }

  def create_blob(filename)
    ActiveStorage::Blob.create_and_upload!(io: File.open(Rails.root.join("spec/fixtures/files/sample.png")),
                                           filename: filename, content_type: "image/png")
  end

  it "保持期間を過ぎた未添付の blob だけを削除する" do
    old_unattached = travel_to((PurgeUnattachedBlobsJob::RETENTION + 1.hour).ago) { create_blob("abandoned.png") }
    old_attached = travel_to((PurgeUnattachedBlobsJob::RETENTION + 1.hour).ago) { create_blob("attached.png") }
    task.images.attach(old_attached)
    recent_unattached = create_blob("staging.png")

    perform_enqueued_jobs { described_class.perform_now }

    expect(ActiveStorage::Blob.exists?(old_unattached.id)).to be(false)
    expect(ActiveStorage::Blob.exists?(old_attached.id)).to be(true)
    expect(ActiveStorage::Blob.exists?(recent_unattached.id)).to be(true)
  end

  it "保持期間は staging の signed_id の有効期限より長い（確認中の blob を消さない）" do
    expect(PurgeUnattachedBlobsJob::RETENTION).to be > TaskImageService::STAGING_EXPIRES_IN
  end
end
