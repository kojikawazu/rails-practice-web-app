require "rails_helper"

# 確認画面（入力 → 確認 → 修正で値保持 → 確定）のブラウザ操作フロー。
# rack_test ドライバ（JS 非依存）で駆動する。
RSpec.describe "確認画面フロー", type: :system do
  let(:user) { create(:user) }

  describe "ユーザー登録" do
    it "入力 → 確認 → 登録でアカウントが作成され一覧へ遷移する" do
      visit signup_path
      fill_in "名前", with: "山田太郎"
      fill_in "メールアドレス", with: "taro@example.com"
      fill_in "パスワード", with: "password123"
      fill_in "パスワード（確認）", with: "password123"

      # 「確認する」では保存されない
      expect { click_button "確認する" }.not_to change(User, :count)
      expect(page).to have_content("入力内容の確認")
      expect(page).to have_content("taro@example.com")

      # 「登録する」で初めて保存され、ログイン状態で一覧へ
      expect { click_button "登録する" }.to change(User, :count).by(1)
      expect(page).to have_current_path(projects_path)
    end

    it "「修正する」で入力フォームに戻り入力値が保持される" do
      visit signup_path
      fill_in "名前", with: "戻る太郎"
      fill_in "メールアドレス", with: "modori@example.com"
      fill_in "パスワード", with: "password123"
      fill_in "パスワード（確認）", with: "password123"
      click_button "確認する"

      expect(page).to have_content("入力内容の確認")
      click_button "修正する"

      expect(page).to have_field("名前", with: "戻る太郎")
      expect(page).to have_field("メールアドレス", with: "modori@example.com")
    end

    it "不正入力（必須未入力）では確認画面に進まずフォームに留まる" do
      visit signup_path
      fill_in "名前", with: ""
      fill_in "メールアドレス", with: ""
      fill_in "パスワード", with: ""

      expect { click_button "確認する" }.not_to change(User, :count)
      expect(page).not_to have_content("入力内容の確認")
      expect(page).to have_content("ユーザー登録")
    end
  end

  describe "プロジェクト作成" do
    before { sign_in_as(user) }

    it "入力 → 確認 → 作成でプロジェクトが作成される" do
      visit new_project_path
      fill_in "タイトル", with: "新規プロジェクト"
      fill_in "説明", with: "説明文"

      expect { click_button "確認する" }.not_to change(Project, :count)
      expect(page).to have_content("入力内容の確認")
      expect(page).to have_content("新規プロジェクト")

      expect { click_button "作成する" }.to change(Project, :count).by(1)
      expect(page).to have_content("プロジェクトを作成しました")
    end

    it "「修正する」で入力値が保持される" do
      visit new_project_path
      fill_in "タイトル", with: "保持タイトル"
      fill_in "説明", with: "保持説明"
      click_button "確認する"
      # 新規は (b案2) のため「修正する」はリンク（session が値を保持）。
      click_on "修正する"

      expect(page).to have_field("タイトル", with: "保持タイトル")
      expect(page).to have_field("説明", with: "保持説明")
    end
  end

  describe "タスク編集" do
    let!(:project) { create(:project, user: user) }
    let!(:task) { create(:task, project: project, title: "元タイトル", status: :not_started) }

    before { sign_in_as(user) }

    it "入力 → 確認 → 更新でタスクが更新される" do
      visit edit_project_task_path(project, task)
      fill_in "タイトル", with: "更新後タイトル"

      click_button "確認する"
      expect(page).to have_content("入力内容の確認")
      expect(page).to have_content("更新後タイトル")

      click_button "更新する"
      expect(page).to have_content("タスクを更新しました")
      expect(task.reload.title).to eq("更新後タイトル")
    end
  end
end
