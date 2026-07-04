# API モードの基底コントローラー。全エンドポイント共通で JWT 認証を要求し、
# サービスの Result を JSON に変換する render_result ヘルパーと、404 の一元ハンドリングを提供する。
# 認証を除外したいコントローラーは `skip_before_action :authenticate_user!` を宣言する。
class ApplicationController < ActionController::API
  before_action :authenticate_user!

  # 他ユーザーの/存在しないリソースへのアクセスは 404 に一元化する。
  # `e.model` が "Project" / "Task" を返すため、モデル別メッセージを単一ハンドラで再現する。
  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: { error: "#{e.model} not found" }, status: :not_found
  end

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

  # サービスの Result に従って JSON レスポンスを render する。
  # 失敗: `{ errors: [...] }`／204: ボディ無し／それ以外の成功: data を Result.status で render。
  #
  # @param result [ApplicationService::Result] サービスの実行結果
  # @return [void]
  def render_result(result)
    if result.failure?
      render json: { errors: result.errors }, status: result.status
    elsif result.status == :no_content
      head :no_content
    else
      render json: result.data, status: result.status
    end
  end
end
