require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "valid user" do
    assert @user.valid?
  end

  test "invalid without name" do
    @user.name = ""
    assert_not @user.valid?
  end

  test "invalid with too long name" do
    @user.name = "a" * 51
    assert_not @user.valid?
  end

  test "invalid without email" do
    @user.email = ""
    assert_not @user.valid?
  end

  test "invalid with duplicate email" do
    duplicate = User.new(name: "別ユーザー", email: @user.email, password: "password123")
    assert_not duplicate.valid?
  end

  test "invalid with malformed email" do
    @user.email = "not_an_email"
    assert_not @user.valid?
  end

  test "authenticate with correct password" do
    assert @user.authenticate("password")
  end

  test "authenticate with wrong password" do
    assert_not @user.authenticate("wrong_password")
  end
end
