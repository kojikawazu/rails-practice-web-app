require "rails_helper"

# TaskImageService は「画像の staging（検証付き blob 化）・signed_id の発行と照合・attach・purge」という実ロジックを持つ。
# AuthService と違い I/O 境界をモックしない: Active Storage の substrate は test 環境で
# Disk（tmp/storage・config は storage.yml / test.rb）として実物が安く動くため、実 blob / attachment で検証する。
# create_and_upload! / attach / purge をモックすると委譲の実装追認になる（docs/08 のモック方針・第3カテゴリ）。
RSpec.describe TaskImageService do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:task) { create(:task) }

  def png_upload = fixture_file_upload("sample.png", "image/png")
  def txt_upload = fixture_file_upload("not_image.txt", "text/plain")

  describe ".stage" do
    it "全て有効なら blob を作って返す" do
      blobs = nil
      expect { blobs = described_class.stage([ png_upload ]) }
        .to change(ActiveStorage::Blob, :count).by(1)
      expect(blobs).to contain_exactly(an_instance_of(ActiveStorage::Blob))
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

  describe ".signed_id_for / .resolve" do
    let(:blob) { described_class.stage([ png_upload ]).first }

    it "発行した利用者で照合すると staging 中の blob を返す" do
      signed_id = described_class.signed_id_for(user, blob)
      expect(described_class.resolve(user, [ signed_id ])).to eq([ blob ])
    end

    it "空配列なら [] を返す" do
      expect(described_class.resolve(user, [])).to eq([])
    end

    it "他の利用者向けに発行された signed_id は拒否して nil を返す（replay 防止）" do
      signed_id = described_class.signed_id_for(other_user, blob)
      expect(described_class.resolve(user, [ signed_id ])).to be_nil
    end

    it "画像 URL に含まれる既定用途の signed_id は拒否する" do
      expect(described_class.resolve(user, [ blob.signed_id ])).to be_nil
    end

    it "改ざんされた signed_id は例外にせず nil を返す" do
      expect(described_class.resolve(user, [ "tampered--signature" ])).to be_nil
    end

    it "期限切れの signed_id は拒否する" do
      signed_id = described_class.signed_id_for(user, blob)
      travel_to(TaskImageService::STAGING_EXPIRES_IN.from_now + 1.minute) do
        expect(described_class.resolve(user, [ signed_id ])).to be_nil
      end
    end

    it "既に添付済みの blob は拒否する（別タスクへの使い回し・二重送信の防止）" do
      signed_id = described_class.signed_id_for(user, blob)
      task.images.attach(blob)
      expect(described_class.resolve(user, [ signed_id ])).to be_nil
    end

    it "1つでも不正が混じれば全体を拒否する（部分的に添付しない）" do
      valid = described_class.signed_id_for(user, blob)
      expect(described_class.resolve(user, [ valid, "tampered--signature" ])).to be_nil
    end
  end

  describe ".attach" do
    it "blob を渡すと task.images が増える" do
      blobs = described_class.stage([ png_upload ])
      expect { described_class.attach(task, blobs) }
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
