module SystemLoginHelper
  # system spec は HTTP ではなくログイン画面の操作でセッションを確立する。
  def sign_in_as(user, password: "password123")
    visit login_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: password
    click_button "ログイン"
  end
end

RSpec.configure do |config|
  config.include SystemLoginHelper, type: :system
end
