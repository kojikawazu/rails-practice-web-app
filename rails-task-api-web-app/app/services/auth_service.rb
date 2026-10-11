# 認証（ユーザー登録・ログイン）のビジネスロジックを担うサービス。
# 成功時は user と発行した JWT を Result の data に格納して返す。
class AuthService < ApplicationService
  # ユーザーを新規登録し、成功時に JWT を発行する。
  #
  # @param params [ActionController::Parameters, Hash] name/email/password/password_confirmation
  # @return [ApplicationService::Result] 成功: data={ user:, token: }（201）／失敗: code=:validation_failed, errors=full_messages
  def self.signup(params)
    user = User.new(params)
    return failure(errors: user.errors.full_messages) unless user.save

    success(data: { user: user, token: JsonWebToken.encode(user_id: user.id) }, status: :created)
  end

  # メールアドレスとパスワードを検証し、成功時に JWT を発行する。
  # メール不在・パスワード誤りは区別せず、同じ理由（invalid_credentials）で失敗させる（列挙攻撃対策）。
  # 利用者に見せる統一メッセージは ErrorSerializer の invalid_credentials が持つ。
  #
  # @param email [String] メールアドレス
  # @param password [String] 平文パスワード
  # @return [ApplicationService::Result] 成功: data={ user:, token: }（200）／失敗: code=:invalid_credentials
  def self.login(email:, password:)
    user = User.find_by(email: email)
    if user&.authenticate(password)
      success(data: { user: user, token: JsonWebToken.encode(user_id: user.id) })
    else
      failure(code: :invalid_credentials)
    end
  end
end
