# フルスタック版の基底コントローラー。セッションベース認証のヘルパーと、例外の一元ハンドリングを提供する。
# current_user / logged_in? はビューからも参照できるよう helper_method に公開する。
class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  helper_method :current_user, :logged_in?

  # 存在しない/他ユーザーのリソースは、各 Controller の current_user 起点の find が RecordNotFound を投げる。
  # 応答はここに集約し、両者を同じ 404 で返して存在を秘匿する（.claude/rules/ruby.md）。
  # リダイレクト＋フラッシュにすると 302 になり秘匿が崩れるため、ステータスは 404 のまま
  # アプリのレイアウトで状況と戻り先を示す（静的な public/404.html には戻り先がない）。
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  # 認証系のレートリミット（rate_limit の with:）を超えたときの応答。
  # 入力フォームを 429 で再描画し、再試行までの秒数を Retry-After で添える。
  # フォームを描画する（リダイレクトしない）のは、PRG で 302 にすると 429 の意味が失われるため。
  #
  # @param template [Symbol] 再描画する入力フォーム（:new 等）
  # @return [void] template を 429 で描画（フラッシュで状況を伝える）
  def render_too_many_requests(template)
    response.headers["Retry-After"] = Rails.configuration.x.rate_limit.auth_period.to_i.to_s
    flash.now[:alert] = "試行回数が多すぎます。しばらく待ってから再度お試しください。"
    render template, status: :too_many_requests
  end

  # RecordNotFound の応答。HTML はレイアウト付きの画面、JSON は統一エラー形式で 404 を返す。
  # 利用者の操作で起きる想定内の事象のため、スタックトレースは記録しない（Rails の標準ログのみ）。
  #
  # @return [void] HTML: errors/not_found を 404 で描画／JSON: { error: "Not found" } を 404／その他: 本文なしの 404
  def render_not_found
    respond_to do |format|
      format.html { render "errors/not_found", status: :not_found }
      format.json { render json: { error: "Not found" }, status: :not_found }
      format.any { head :not_found }
    end
  end

  # セッションの user_id から現在のユーザーを取得する（1 リクエスト内でメモ化）。
  #
  # @return [User, nil] ログイン中のユーザー。未ログイン時は nil
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  # ログイン済みかどうかを返す。
  #
  # @return [Boolean] ログイン中なら true
  def logged_in?
    current_user.present?
  end

  # ログイン必須アクションの before_action。未ログインならログイン画面へ誘導する。
  #
  # @return [void] 未ログイン時はログイン画面へリダイレクト
  def require_login
    unless logged_in?
      redirect_to login_path, alert: "ログインしてください。"
    end
  end
end
