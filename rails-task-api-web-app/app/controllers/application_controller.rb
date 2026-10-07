# API モードの基底コントローラー。全エンドポイント共通で JWT 認証を要求し、
# サービスの Result を JSON に変換する render_result ヘルパーと、404 の一元ハンドリング、
# API 全体のレートリミットを提供する。
# 認証を除外したいコントローラーは `skip_before_action :authenticate_user!` を宣言する。
class ApplicationController < ActionController::API
  # API 全体のレートリミット（同一 IP 単位・緩め）。authenticate_user! より前に置き、
  # 認証に失敗するリクエスト（トークンの総当たり等）も数える。scope を固定してカウンタを
  # 全コントローラーで共有し、エンドポイントを切り替えて上限を回避できないようにする
  # （既定の scope は controller_path で、コントローラーごとに別カウンタになる）。
  rate_limit to: Rails.configuration.x.rate_limit.api_limit,
             within: Rails.configuration.x.rate_limit.api_period,
             scope: "api",
             with: -> { render_too_many_requests(retry_after: Rails.configuration.x.rate_limit.api_period) }

  before_action :authenticate_user!

  # 他ユーザーの/存在しないリソースへのアクセスは 404 に一元化する。
  # `e.model` が "Project" / "Task" を返すため、モデル別メッセージを単一ハンドラで再現する。
  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: { error: "#{e.model} not found" }, status: :not_found
  end

  private

  # レートリミット超過時の応答。統一エラー形式の 429 に、再試行までの秒数を Retry-After で添える。
  #
  # @param retry_after [ActiveSupport::Duration] カウンタが失効するまでの期間（rate_limit の within）
  # @return [void] `{ error: "Too many requests" }` を 429 で render
  def render_too_many_requests(retry_after:)
    response.headers["Retry-After"] = retry_after.to_i.to_s
    render json: { error: "Too many requests" }, status: :too_many_requests
  end

  # `Authorization: Bearer <token>` ヘッダーを検証し、@current_user を確定する。
  # トークンが無効・ユーザー未存在の場合は 401 を返して処理を中断する。
  #
  # @return [void] 認証失敗時は `{ error: "Unauthorized" }` を 401 で render
  def authenticate_user!
    decoded = JsonWebToken.decode(bearer_token)

    if decoded
      @current_user = User.find_by(id: decoded[:user_id])
    end

    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
  end

  # Authorization ヘッダーから Bearer スキームの資格情報だけを取り出す。
  #
  # 認証境界は文書化した契約（07-api-specification.md）どおりに閉じる。scheme を見ずに
  # 末尾の要素を token として扱うと `Basic <jwt>` や `Anything ignored <jwt>` まで
  # 同じ資格情報として通り、プロキシ・クライアント・監査ログが前提にする搬送方式が崩れる。
  # scheme の大文字小文字は区別しない（RFC 7235: auth-scheme is case-insensitive）。
  #
  # @return [String, nil] Bearer の token。契約に合わない形式なら nil（＝401 になる）
  def bearer_token
    scheme, credentials, *extra = request.headers["Authorization"].to_s.split(" ")
    return nil unless extra.empty?
    return nil unless scheme&.casecmp?("Bearer")

    credentials.presence
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
