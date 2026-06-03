module SystemLoginHelper
  # system spec は HTTP ではなくログイン画面の操作でセッションを確立する。
  def sign_in_as(user, password: "password123")
    visit login_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: password
    click_button "ログイン"
    # Turbo の非同期送信が完了し、セッションが確立するまで待つ（レース防止）。
    expect(page).to have_current_path(projects_path)
  end
end

RSpec.configure do |config|
  config.include SystemLoginHelper, type: :system
end
