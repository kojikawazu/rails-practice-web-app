require 'rails_helper'

RSpec.describe Task, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(200) }

    it 'is valid with a title of exactly 200 characters' do
      expect(build(:task, title: 'a' * 200)).to be_valid
    end

    it 'is invalid with a title of 201 characters' do
      expect(build(:task, title: 'a' * 201)).not_to be_valid
    end

    it 'is invalid with an unknown status' do
      task = build(:task)
      task.status = 99
      expect(task).not_to be_valid
    end
  end

  describe '開始日・終了日' do
    it '両方未入力でも有効（任意項目）' do
      expect(build(:task, start_date: nil, end_date: nil)).to be_valid
    end

    it '片方のみ（開始日だけ）でも有効' do
      expect(build(:task, start_date: Date.current, end_date: nil)).to be_valid
    end

    it '終了日が開始日と同じ日なら有効（境界値）' do
      expect(build(:task, start_date: Date.current, end_date: Date.current)).to be_valid
    end

    it '終了日が開始日より後なら有効' do
      expect(build(:task, start_date: Date.current, end_date: Date.current + 1)).to be_valid
    end

    it '終了日が開始日より前だと無効' do
      task = build(:task, start_date: Date.current, end_date: Date.current - 1)
      expect(task).not_to be_valid
      expect(task.errors[:end_date]).to be_present
    end
  end

  describe '添付画像のバリデーション' do
    it 'PNG 画像は添付でき valid' do
      task = build(:task)
      task.images.attach(io: File.open(Rails.root.join('spec/fixtures/files/sample.png')),
                         filename: 'sample.png', content_type: 'image/png')
      expect(task).to be_valid
    end

    it '非画像（text/plain）は invalid' do
      task = build(:task)
      task.images.attach(io: StringIO.new('not image'),
                         filename: 'a.txt', content_type: 'text/plain')
      expect(task).not_to be_valid
      expect(task.errors[:images]).to be_present
    end
  end

  describe 'preview_url のバリデーション' do
    it '空（未入力）は valid' do
      expect(build(:task, preview_url: nil)).to be_valid
      expect(build(:task, preview_url: '')).to be_valid
    end

    it 'http / https の URL は valid' do
      expect(build(:task, preview_url: 'http://example.com')).to be_valid
      expect(build(:task, preview_url: 'https://example.com/path?q=1')).to be_valid
    end

    it 'javascript: スキームは invalid（XSS 防止）' do
      task = build(:task, preview_url: 'javascript:alert(document.cookie)')
      expect(task).not_to be_valid
      expect(task.errors[:preview_url]).to be_present
    end

    it 'data: スキームは invalid' do
      task = build(:task, preview_url: 'data:text/html,<script>alert(1)</script>')
      expect(task).not_to be_valid
    end

    it 'ftp など http/https 以外のスキームは invalid' do
      expect(build(:task, preview_url: 'ftp://example.com/file')).not_to be_valid
    end

    it 'ホストの無い不正な URL は invalid' do
      expect(build(:task, preview_url: 'http://')).not_to be_valid
      expect(build(:task, preview_url: 'not a url')).not_to be_valid
    end

    it '上限文字数を超える URL は invalid' do
      long = 'https://example.com/' + ('a' * Task::MAX_PREVIEW_URL_LENGTH)
      expect(build(:task, preview_url: long)).not_to be_valid
    end

    it 'localhost / 内部・ループバック・プライベート IP は invalid（sandbox 脱獄経路の遮断）' do
      %w[
        http://localhost:3000/
        http://127.0.0.1/
        http://0.0.0.0/
        http://10.0.0.5/
        http://192.168.1.10/
        http://169.254.169.254/
      ].each do |url|
        expect(build(:task, preview_url: url)).not_to be_valid, "#{url} は拒否されるべき"
      end
    end

    it 'IPv6 リテラル・FQDN 末尾ドット等の表記揺れも拒否（正規化バイパス防止）' do
      %w[
        http://[::1]/
        http://[fe80::1]/
        http://[fd00::1]/
        http://localhost./
        http://127.0.0.1./
      ].each do |url|
        expect(build(:task, preview_url: url)).not_to be_valid, "#{url} は拒否されるべき"
      end
    end

    it '自アプリのホスト（app_host 一致）は invalid（自オリジン埋め込み拒否）' do
      task = build(:task, preview_url: 'https://myapp.example/path')
      task.app_host = 'myapp.example'
      expect(task).not_to be_valid
      expect(task.errors[:preview_url]).to be_present
    end

    it '外部の通常ホストは app_host を設定しても valid' do
      task = build(:task, preview_url: 'https://other.example/path')
      task.app_host = 'myapp.example'
      expect(task).to be_valid
    end
  end

  describe 'enum status' do
    it 'defaults to not_started without factory' do
      # factory を使わず Task.new でモデル本来のデフォルトを検証する
      task = Task.new
      expect(task.not_started?).to be true
    end
  end

  describe 'ステータス遷移（docs/03 のステータス遷移図＝業務制約）' do
    context '新規作成' do
      it '未着手（not_started）なら作成できる' do
        expect(build(:task, status: :not_started)).to be_valid
      end

      it '進行中を指定した作成は、遷移の起点を飛ばすため無効' do
        task = build(:task, status: :in_progress)
        expect(task).not_to be_valid
        expect(task.errors[:status]).to be_present
      end

      it '完了を指定した作成は、遷移の起点を飛ばすため無効' do
        task = build(:task, status: :completed)
        expect(task).not_to be_valid
        expect(task.errors[:status]).to be_present
      end
    end

    context '更新' do
      it '未着手 → 進行中 は許可する' do
        task = create(:task)
        expect(task.update(status: :in_progress)).to be true
      end

      it '進行中 → 完了 は許可する' do
        task = create(:task, :in_progress)
        expect(task.update(status: :completed)).to be true
      end

      it '完了 → 進行中 は差し戻しとして許可する' do
        task = create(:task, :completed)
        expect(task.update(status: :in_progress)).to be true
      end

      it '未着手 → 完了 は途中を飛ばすため拒否し、DB の値も変えない' do
        task = create(:task)
        expect(task.update(status: :completed)).to be false
        expect(task.reload.status).to eq('not_started')
      end

      it '進行中 → 未着手 は拒否する（差し戻しは完了からのみ）' do
        task = create(:task, :in_progress)
        expect(task.update(status: :not_started)).to be false
        expect(task.reload.status).to eq('in_progress')
      end

      it '完了 → 未着手 は拒否する（一気に起点まで戻さない）' do
        task = create(:task, :completed)
        expect(task.update(status: :not_started)).to be false
        expect(task.reload.status).to eq('completed')
      end

      it 'ステータスを変えない更新は、どの状態でも許可する' do
        task = create(:task, :completed)
        expect(task.update(title: 'タイトルだけ変更')).to be true
      end
    end
  end
end
