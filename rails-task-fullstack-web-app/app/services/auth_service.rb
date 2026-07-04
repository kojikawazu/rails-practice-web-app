# 認証（ユーザー登録・ログイン）のビジネスロジックを担うサービス。
# フルスタック版はセッション認証のため JWT を発行せず、レコード / nil を返す
# （API 版のような Result 値オブジェクトは使わない）。session への格納は Controller が行う。
class AuthService
  # ユーザーを新規登録する。保存の成否に関わらずレコードを返し、
  # 呼び出し側は persisted? / errors で分岐してフォームを再描画できるようにする。
  #
  # @param params [ActionController::Parameters, Hash] name/email/password/password_confirmation
  # @return [User] 保存済み（persisted? == true）または検証失敗で errors を保持したレコード
  def self.signup(params)
    User.new(params).tap(&:save)
  end

  # メール・パスワードを検証する。メール不在・パスワード誤りは区別せず nil を返す
  # （列挙攻撃対策）。認証の可否という実ロジックを持つため UT の価値がある。
  #
  # @param email [String] メールアドレス
  # @param password [String] 平文パスワード
  # @return [User, nil] 認証成功なら該当ユーザー／失敗なら nil
  def self.login(email:, password:)
    user = User.find_by(email: email)
    user&.authenticate(password) ? user : nil
  end
end
