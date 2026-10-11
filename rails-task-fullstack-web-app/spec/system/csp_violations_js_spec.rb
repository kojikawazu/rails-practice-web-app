require "rails_helper"

# CSP 違反は「ブロックされた資源が黙って効かない」だけで、画面操作は成功してしまう。
# rack_test は CSP を解釈しないため、実ブラウザ（headless Chrome）のコンソールログで検出する（:js）。
#
# 回帰ガードの対象: Turbo はプログレスバーの CSS を <style> として <head> に挿入し、
# <meta name="csp-nonce"> の nonce を付ける。style-src に nonce が無いとこの <style> が
# ブロックされる（#132）。挿入は Turbo の起動時（フルページ読み込みごと）に 1 回行われる。
RSpec.describe "CSP 違反（JS / Turbo 有効）", type: :system, js: true do
  let(:user) { create(:user) }
  let!(:project) { create(:project, user: user, title: "CSP 確認用プロジェクト") }

  # 取得済みのログは消費されるため、呼び出すたびに「前回の取得以降」のログが返る。
  def browser_log_messages
    page.driver.browser.logs.get(:browser).map(&:message)
  end

  it "ログインから Turbo 遷移まで、ブラウザに CSP 違反を出さない" do
    sign_in_as(user)

    # Turbo Drive の遷移（フルページ読み込みではない）も通す。
    within("tbody tr", text: "CSP 確認用プロジェクト") { click_link "編集" }
    expect(page).to have_current_path(edit_project_path(project))

    # ログ取得の設定が外れると「違反ゼロ」が素通りで成功するため、
    # 既知のメッセージが取得できることを同じログで確かめてから違反を検査する。
    page.execute_script("console.error('csp-spec-log-probe')")
    messages = browser_log_messages

    expect(messages).to include(a_string_including("csp-spec-log-probe"))
    expect(messages.grep(/Content Security Policy/)).to be_empty
  end
end
