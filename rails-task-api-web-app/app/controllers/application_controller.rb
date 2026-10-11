# API モードの基底コントローラー。全エンドポイント共通で JWT 認証を要求し、
# サービスの Result を JSON に変換する render_result ヘルパーと、想定内のエラー（400 / 404）の
# 一元ハンドリング、API 全体のレートリミットを提供する。
#
# エラーはすべて render_error（ErrorSerializer）を通し、`{ error: { code:, message:, details: } }` の
# 1 形態で返す。ここで扱うのはコントローラーに届く想定内のエラーで、全環境で同じ形になる。
# コントローラーに届かないルーターの 404 と想定外の 500 は exceptions_app（ErrorsController）が扱う。
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
    render_error(:not_found, message: "#{e.model} not found")
  end

  # 必須パラメータの欠落（params.require）と壊れた JSON を 400 にする。
  # パラメータは params を最初に読んだ時点で解析される（遅延評価）ため、ParseError もここで捕捉できる。
  # パーサの例外メッセージには送られた本文の断片が入るため、message は固定にして応答に反射させない。
  rescue_from ActionController::ParameterMissing, ActionDispatch::Http::Parameters::ParseError do
    render_error(:bad_request)
  end

  private

  # エラーレスポンスを render する。形と HTTP ステータスは code から ErrorSerializer が決める。
  #
  # @param code [Symbol] ErrorSerializer の code
  # @param message [String, nil] 既定の message を差し替える場合に渡す
  # @param details [Array<String>, nil] バリデーションの内訳
  # @return [void] `{ error: { code:, message:, details: } }` を code に対応するステータスで render
  def render_error(code, message: nil, details: nil)
    render json: ErrorSerializer.render(code, message: message, details: details),
           status: ErrorSerializer.status_for(code)
  end

  # レートリミット超過時の応答。統一エラー形式の 429 に、再試行までの秒数を Retry-After で添える。
  #
  # @param retry_after [ActiveSupport::Duration] カウンタが失効するまでの期間（rate_limit の within）
  # @return [void] code: rate_limited を 429 で render
  def render_too_many_requests(retry_after:)
    response.headers["Retry-After"] = retry_after.to_i.to_s
    render_error(:rate_limited)
  end

  # `Authorization: Bearer <token>` ヘッダーを検証し、@current_user を確定する。
  # トークンが無効・ユーザー未存在の場合は 401 を返して処理を中断する。
  #
  # @return [void] 認証失敗時は code: unauthorized を 401 で render
  def authenticate_user!
    decoded = JsonWebToken.decode(bearer_token)

    if decoded
      @current_user = User.find_by(id: decoded[:user_id])
    end

    render_error(:unauthorized) unless @current_user
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
  # 失敗: Result.code のエラー（内訳は details）／204: ボディ無し／それ以外の成功: data を serializer で整形して Result.status で render。
  #
  # Service はモデルを返し、公開属性への変換はここ（HTTP 層）で行う。data を素通しで render する
  # 分岐は持たない。ボディを返す Result で serializer を渡し忘れると nil.render で落ちるため、
  # 渡し忘れがモデルの全カラム露出につながらない。
  #
  # @param result [ApplicationService::Result] サービスの実行結果
  # @param serializer [Class<ApplicationSerializer>, nil] 成功時の data を整形する serializer（204 のみ省略可）
  # @return [void]
  def render_result(result, serializer: nil)
    if result.failure?
      render_error(result.code, details: result.errors)
    elsif result.status == :no_content
      head :no_content
    else
      render json: serializer.render(result.data), status: result.status
    end
  end
end
