# フルスタック版の基底コントローラー。セッションベース認証のヘルパーを提供する。
# current_user / logged_in? はビューからも参照できるよう helper_method に公開する。
class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  helper_method :current_user, :logged_in?

  private

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
