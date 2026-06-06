require "rails_helper"

# 確認画面フロー（入力 → 確認 → 確定）を実ブラウザ（Turbo 有効）で検証する。
# rack_test 版（confirm_flows_spec.rb）は JS 非依存のため Turbo を通さず、
# 「Turbo Drive が非リダイレクトの 200 描画を破棄して確認画面に進めない」不具合を
# 検知できなかった。本 spec は headless Chrome で実 Turbo 挙動を再現し、回帰を防ぐ。
# 実行: bundle exec rspec --tag js
#
# 注意: 確認画面フォームは data: { turbo: false } によりネイティブのフルページ送信となる。
# このため `expect { click }.to change(count)` は使わず、必ず遷移後ページの内容を
# have_content で待機（Capybara が自動リトライ）してから DB を検証する。早すぎる
# カウント評価による false negative（フレーク）を防ぐためのパターン。
RSpec.describe "確認画面フロー（JS / Turbo 有効）", type: :system, js: true do
  it "ユーザー登録: 入力 → 確認画面表示 → 登録でアカウント作成され一覧へ遷移する" do
    visit signup_path
    fill_in "名前", with: "山田太郎"
    fill_in "メールアドレス", with: "taro@example.com"
    fill_in "パスワード", with: "password123"
    fill_in "パスワード（確認）", with: "password123"

    # Turbo 有効下でも「確認する」で確認画面が描画されること（不具合時はフォームに留まる）。
    click_button "確認する"
    expect(page).to have_content("入力内容の確認")
    expect(page).to have_content("taro@example.com")
    expect(User.count).to eq(0) # 確認段階では未保存

    # 「登録する」で初めて保存され、ログイン状態で一覧へ遷移する。
    click_button "登録する"
    expect(page).to have_current_path(projects_path)
    expect(User.where(email: "taro@example.com")).to exist
  end

  describe "プロジェクト" do
    let(:user) { create(:user) }

    before { sign_in_as(user) }

    it "作成: 入力 → 確認画面表示 → 作成でプロジェクトが作成される" do
      visit new_project_path
      fill_in "タイトル", with: "新規プロジェクト"
      fill_in "説明", with: "説明文"

      click_button "確認する"
      expect(page).to have_content("入力内容の確認")
      expect(page).to have_content("新規プロジェクト")
      expect(Project.where(title: "新規プロジェクト")).not_to exist # 確認段階では未保存

      click_button "作成する"
      expect(page).to have_content("プロジェクトを作成しました")
      expect(Project.where(title: "新規プロジェクト")).to exist
    end

    it "複製: 複製 → 確認画面表示 → 作成で『〜のコピー』が新規作成される" do
      create(:project, user: user, title: "複製元プロジェクト", description: "元の説明")

      visit projects_path
      click_link "複製"

      # 複製元の値が初期入力された新規フォームが開く。
      expect(page).to have_field("タイトル", with: "複製元プロジェクトのコピー")

      click_button "確認する"
      expect(page).to have_content("入力内容の確認")
      expect(Project.where(title: "複製元プロジェクトのコピー")).not_to exist # 確認段階では未保存

      click_button "作成する"
      expect(page).to have_content("プロジェクトを作成しました")
      expect(Project.where(title: "複製元プロジェクトのコピー")).to exist
    end
  end

  describe "タスク（flatpickr 日付入力）" do
    let(:user) { create(:user) }
    let!(:project) { create(:project, user: user, title: "対象プロジェクト") }

    before { sign_in_as(user) }

    it "作成: flatpickr の開始日・終了日を入力 → 確認 → 作成で保存される" do
      visit new_project_task_path(project)
      fill_in "タイトル", with: "日付付きタスク"
      # flatpickr は allowInput: true のため text input へ直接入力できる。
      fill_in "開始日", with: "2026-07-01"
      fill_in "終了日", with: "2026-07-10"

      click_button "確認する"
      expect(page).to have_content("入力内容の確認")
      expect(page).to have_content("2026-07-01")
      expect(page).to have_content("2026-07-10")

      click_button "作成する"
      expect(page).to have_content("タスクを作成しました")
      task = Task.find_by(title: "日付付きタスク")
      expect(task.start_date).to eq(Date.new(2026, 7, 1))
      expect(task.end_date).to eq(Date.new(2026, 7, 10))
    end
  end
end
