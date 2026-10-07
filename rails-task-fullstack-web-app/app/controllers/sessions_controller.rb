# ログイン・ログアウトを扱うコントローラー。認証状態は session[:user_id] で管理する。
#
# パスワードの総当たりを抑えるため、ログイン（create）にレートリミットを掛ける（.claude/rules/security.md）。
# 単位は IP のみとし、メールアドレス単位にはしない（他人のアドレスで上限まで失敗させ、
# その利用者をログインできなくする DoS を避けるため）。
class SessionsController < ApplicationController
  rate_limit to: Rails.configuration.x.rate_limit.auth_limit,
             within: Rails.configuration.x.rate_limit.auth_period,
             only: :create,
             with: -> { render_too_many_requests(:new) }
  # ログインフォームを表示する。
  #
  # @return [void] new ビューを描画
  def new
  end

  # ログイン処理。認証は AuthService に委譲し、成功時にセッションを確立する。
  #
  # @return [void] 成功: プロジェクト一覧へリダイレクト／失敗: new を 422 で再描画
  def create
    user = AuthService.login(email: params[:email], password: params[:password])

    if user
      session[:user_id] = user.id
      redirect_to projects_path, notice: "ログインしました。"
    else
      flash.now[:alert] = "メールアドレスまたはパスワードが正しくありません。"
      render :new, status: :unprocessable_entity
    end
  end

  # ログアウト処理。セッションを破棄してログイン画面へ戻す。
  #
  # @return [void] ログイン画面へ 303 リダイレクト
  def destroy
    session.delete(:user_id)
    @current_user = nil
    redirect_to login_path, notice: "ログアウトしました。", status: :see_other
  end
end
