require "rails_helper"

# TaskImageService は「画像の staging（検証付き blob 化）・attach・purge」という実ロジックを持つ。
# AuthService と違い I/O 境界をモックしない: Active Storage の substrate は test 環境で
# Disk（tmp/storage・config は storage.yml / test.rb）として実物が安く動くため、実 blob / attachment で検証する。
# create_and_upload! / attach / purge をモックすると委譲の実装追認になる（docs/08 のモック方針・第3カテゴリ）。
RSpec.describe TaskImageService do
  let(:task) { create(:task) }

  def png_upload = fixture_file_upload("sample.png", "image/png")
  def txt_upload = fixture_file_upload("not_image.txt", "text/plain")

  describe ".stage" do
    it "全て有効なら blob を作り signed_id 配列を返す" do
      ids = nil
      expect { ids = described_class.stage([ png_upload ]) }
        .to change(ActiveStorage::Blob, :count).by(1)
      expect(ids.size).to eq(1)
      expect(ActiveStorage::Blob.find_signed(ids.first)).to be_present
    end

    it "1つでも不正なファイルがあれば blob を一切作らず nil を返す（オーファン防止）" do
      result = :unset
      expect { result = described_class.stage([ png_upload, txt_upload ]) }
        .not_to change(ActiveStorage::Blob, :count)
      expect(result).to be_nil
    end

    it "アップロードが空なら [] を返す" do
      expect(described_class.stage([])).to eq([])
    end
  end

  describe ".attach" do
    it "signed_id を渡すと task.images が増える" do
      signed_ids = described_class.stage([ png_upload ])
      expect { described_class.attach(task, signed_ids) }
        .to change { task.reload.images.count }.by(1)
    end

    it "空配列なら何もしない" do
      expect { described_class.attach(task, []) }
        .not_to change { task.reload.images.count }
    end
  end

  describe ".purge" do
    it "指定した attachment を削除する" do
      task.images.attach(io: File.open(Rails.root.join("spec/fixtures/files/sample.png")),
                         filename: "sample.png", content_type: "image/png")
      attachment_id = task.images_attachments.first.id
      expect { described_class.purge(task, [ attachment_id ]) }
        .to change { task.reload.images.count }.by(-1)
    end
  end
end
