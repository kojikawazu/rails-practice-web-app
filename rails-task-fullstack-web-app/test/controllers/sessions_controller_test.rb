require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should get login form" do
    get login_url
    assert_response :success
  end

  test "should login with valid credentials" do
    post login_url, params: { email: @user.email, password: "password" }
    assert_redirected_to projects_url
  end

  test "should not login with wrong password" do
    post login_url, params: { email: @user.email, password: "wrong_password" }
    assert_response :unprocessable_entity
  end

  test "should not login with unknown email" do
    post login_url, params: { email: "nobody@example.com", password: "password" }
    assert_response :unprocessable_entity
  end

  test "should logout" do
    log_in_as(@user)
    delete logout_url
    assert_redirected_to login_url
  end
end
