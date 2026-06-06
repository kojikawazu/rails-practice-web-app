require "rails_helper"

# 確認画面フロー（入力 → 確認 → 確定）を実ブラウザ（Turbo 有効）で検証する。
# rack_test 版（confirm_flows_spec.rb）は JS 非依存のため Turbo を通さず、
# 「Turbo Drive が非リダイレクトの 200 描画を破棄して確認画面に進めない」不具合を
# 検知できなかった。本 spec は headless Chrome で実 Turbo 挙動を再現し、回帰を防ぐ。
# 実行: bundle exec rspec --tag js
RSpec.describe "確認画面フロー（JS / Turbo 有効）", type: :system, js: true do
  it "ユーザー登録: 入力 → 確認画面表示 → 登録でアカウント作成され一覧へ遷移する" do
    visit signup_path
    fill_in "名前", with: "山田太郎"
    fill_in "メールアドレス", with: "taro@example.com"
    fill_in "パスワード", with: "password123"
    fill_in "パスワード（確認）", with: "password123"

    # Turbo 有効下でも「確認する」で確認画面が描画されること（不具合時はフォームに留まる）。
    expect { click_button "確認する" }.not_to change(User, :count)
    expect(page).to have_content("入力内容の確認")
    expect(page).to have_content("taro@example.com")

    # 「登録する」で初めて保存され、ログイン状態で一覧へ遷移する。
    expect { click_button "登録する" }.to change(User, :count).by(1)
    expect(page).to have_current_path(projects_path)
  end

  describe "プロジェクト" do
    let(:user) { create(:user) }

    before { sign_in_as(user) }

    it "作成: 入力 → 確認画面表示 → 作成でプロジェクトが作成される" do
      visit new_project_path
      fill_in "タイトル", with: "新規プロジェクト"
      fill_in "説明", with: "説明文"

      expect { click_button "確認する" }.not_to change(Project, :count)
      expect(page).to have_content("入力内容の確認")
      expect(page).to have_content("新規プロジェクト")

      expect { click_button "作成する" }.to change(Project, :count).by(1)
      expect(page).to have_content("プロジェクトを作成しました")
    end

    it "複製: 複製 → 確認画面表示 → 作成で『〜のコピー』が新規作成される" do
      create(:project, user: user, title: "複製元プロジェクト", description: "元の説明")

      visit projects_path
      click_link "複製"

      # 複製元の値が初期入力された新規フォームが開く。
      expect(page).to have_field("タイトル", with: "複製元プロジェクトのコピー")

      expect { click_button "確認する" }.not_to change(Project, :count)
      expect(page).to have_content("入力内容の確認")

      expect { click_button "作成する" }.to change(Project, :count).by(1)
      expect(Project.where(title: "複製元プロジェクトのコピー")).to exist
    end
  end
end
