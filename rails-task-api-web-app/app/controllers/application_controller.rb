# API モードの基底コントローラー。全エンドポイント共通で JWT 認証を要求する。
# 認証を除外したいコントローラーは `skip_before_action :authenticate_user!` を宣言する。
class ApplicationController < ActionController::API
  before_action :authenticate_user!

  private

  # `Authorization: Bearer <token>` ヘッダーを検証し、@current_user を確定する。
  # トークンが無効・ユーザー未存在の場合は 401 を返して処理を中断する。
  #
  # @return [void] 認証失敗時は `{ error: "Unauthorized" }` を 401 で render
  def authenticate_user!
    token = request.headers["Authorization"]&.split(" ")&.last
    decoded = JsonWebToken.decode(token)

    if decoded
      @current_user = User.find_by(id: decoded[:user_id])
    end

    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
  end

  # 認証済みユーザーを返す（authenticate_user! で確定済み）。
  #
  # @return [User, nil] ログイン中のユーザー
  def current_user
    @current_user
  end
end
