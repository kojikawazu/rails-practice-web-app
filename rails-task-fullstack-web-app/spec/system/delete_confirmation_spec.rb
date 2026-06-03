require "rails_helper"

# 削除時の turbo_confirm ダイアログ（JS 必須）の挙動。
# headless Chrome（selenium）が必要なため :js タグを付け、通常の rspec からは除外する。
# 実行: bundle exec rspec --tag js
#
# selenium の連続ログインは sandbox 環境で不安定なため、ログインは 1 回だけ行い、
# 承認/キャンセル/タスク削除の各挙動を 1 example 内で検証する。
RSpec.describe "削除確認ダイアログ", type: :system, js: true do
  let(:user) { create(:user) }
  let!(:keep_project) { create(:project, user: user, title: "残すプロジェクト") }
  let!(:delete_project) { create(:project, user: user, title: "消すプロジェクト") }
  let!(:delete_task) { create(:task, project: keep_project, title: "消すタスク") }

  it "turbo_confirm を承認すると削除され、キャンセルすると削除されない" do
    sign_in_as(user)

    # キャンセル → プロジェクトは残る
    visit project_path(keep_project)
    dismiss_confirm { click_button "削除" }
    expect(page).to have_content("残すプロジェクト")
    expect(Project.exists?(keep_project.id)).to be(true)

    # 承認 → タスクが削除される
    visit project_task_path(keep_project, delete_task)
    accept_confirm { click_button "削除" }
    expect(page).to have_content("タスクを削除しました")
    expect(Task.exists?(delete_task.id)).to be(false)

    # 承認 → プロジェクトが削除される
    visit project_path(delete_project)
    accept_confirm { click_button "削除" }
    expect(page).to have_content("プロジェクトを削除しました")
    expect(Project.exists?(delete_project.id)).to be(false)
  end
end
