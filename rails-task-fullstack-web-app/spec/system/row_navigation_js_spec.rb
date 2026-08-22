require "rails_helper"

# 一覧の行クリック遷移は実ブラウザの DOM イベントに依存し、rack_test では検証できないため :js を付ける。
# CSP を enforce にした後はインライン onclick がブラウザ側でブロックされるため、
# この spec は「Stimulus への移行が実際に効いている」ことの回帰ガードでもある。
RSpec.describe "一覧の行クリック", type: :system, js: true do
  let(:user) { create(:user) }
  let!(:project) { create(:project, user: user, title: "行クリック用プロジェクト") }

  it "行のクリックで詳細へ遷移し、行内の編集リンクは編集画面へ遷移する" do
    sign_in_as(user)

    # 行の空白部分（タイトルのセル）をクリックすると詳細へ。
    visit projects_path
    find("tbody tr", text: "行クリック用プロジェクト").find("td", match: :first).click
    expect(page).to have_current_path(project_path(project))

    # 行内のリンクは行の遷移に飲まれず、本来の遷移先へ進む。
    visit projects_path
    within("tbody tr", text: "行クリック用プロジェクト") { click_link "編集" }
    expect(page).to have_current_path(edit_project_path(project))
  end
end
