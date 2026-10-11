# exceptions_app（config/application.rb）として、コントローラーに届かないエラー（ルーターの 404）と
# 想定外の例外（500）を、統一エラー形式 `{ error: { code:, message: } }` で返す。
#
# ShowExceptions ミドルウェアが、詳細表示がオフ（本番相当）のときだけここを呼ぶ。development と test の
# 既定ではデバッグ表示が優先される（開発中に 500 のスタックトレースを見えなくしないため）。
# 想定内のエラー（400 / 401 / 404 / 422 / 429）は ApplicationController が全環境で同じ形に整形する。
#
# ApplicationController を継承しない。認証・レートリミットの before_action を通すと、
# エラーの応答そのものが 401 / 429 に化けるため。
class ErrorsController < ActionController::API
  # ShowExceptions は、例外に対応するステータスコードを PATH_INFO（例: "/404"）に入れて呼び出す。
  # 404 以外の 4xx（405 など）は API の通常の経路では起きないため、まとめて bad_request（400）にする。
  # 例外の内容は応答に含めない（内部実装の情報を外へ出さない）。
  #
  # @return [void] code: not_found（404）／bad_request（400）／internal_error（500）を render
  def show
    code = code_for(request.path_info.delete_prefix("/").to_i)
    render json: ErrorSerializer.render(code), status: ErrorSerializer.status_for(code)
  end

  private

  # @param status [Integer] ShowExceptions が渡した HTTP ステータス
  # @return [Symbol] ErrorSerializer の code
  def code_for(status)
    return :not_found if status == 404
    return :bad_request if status.between?(400, 499)

    :internal_error
  end
end
