module Api
  module V1
    # 認証エンドポイント（ユーザー登録・ログイン）。ロジックは AuthService に委譲し、
    # ここでは Strong Parameters とレスポンス整形（token + UserSerializer）に専念する。
    # 認証前でも叩けるよう、基底の authenticate_user! をスキップする。
    #
    # login（パスワードの総当たり）と signup（アカウントの大量作成）には、API 全体より厳しい
    # レートリミットを掛ける（.claude/rules/security.md）。目的が違うため name でカウンタを分け、
    # 登録の失敗でログインまで止まらないようにする。単位は IP のみとし、メールアドレス単位にはしない
    # （他人のアドレスで上限まで失敗させ、その利用者をログインできなくする DoS を避けるため）。
    class AuthController < ApplicationController
      skip_before_action :authenticate_user!

      rate_limit to: Rails.configuration.x.rate_limit.auth_limit,
                 within: Rails.configuration.x.rate_limit.auth_period,
                 name: "login", only: :login,
                 with: -> { render_too_many_requests(retry_after: Rails.configuration.x.rate_limit.auth_period) }
      rate_limit to: Rails.configuration.x.rate_limit.auth_limit,
                 within: Rails.configuration.x.rate_limit.auth_period,
                 name: "signup", only: :signup,
                 with: -> { render_too_many_requests(retry_after: Rails.configuration.x.rate_limit.auth_period) }

      # ユーザー登録。成功時は JWT とユーザー情報を 201 で返す。
      #
      # @return [void] 成功: `{ token:, user: }`（201）／失敗: code: validation_failed（422）
      def signup
        result = AuthService.signup(user_params)
        if result.success?
          render json: { token: result.data[:token], user: UserSerializer.render(result.data[:user]) }, status: :created
        else
          render_error(result.code, details: result.errors)
        end
      end

      # ログイン。メール・パスワード一致時に JWT を発行する。
      #
      # @return [void] 成功: `{ token:, user: }`（200）／失敗: code: invalid_credentials（401）
      def login
        result = AuthService.login(email: params[:email], password: params[:password])
        if result.success?
          render json: { token: result.data[:token], user: UserSerializer.render(result.data[:user]) }
        else
          render_error(result.code)
        end
      end

      private

      # Strong Parameters。登録フォームから受け取る許可カラムのみを抽出する。
      #
      # @return [ActionController::Parameters] name / email / password / password_confirmation
      def user_params
        params.require(:user).permit(:name, :email, :password, :password_confirmation)
      end
    end
  end
end
