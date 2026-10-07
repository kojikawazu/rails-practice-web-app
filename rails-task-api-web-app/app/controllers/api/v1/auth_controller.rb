module Api
  module V1
    # 認証エンドポイント（ユーザー登録・ログイン）。ロジックは AuthService に委譲し、
    # ここでは Strong Parameters とレスポンス整形（token + user_json）に専念する。
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
      # @return [void] 成功: `{ token:, user: }`（201）／失敗: `{ errors: [...] }`（422）
      def signup
        result = AuthService.signup(user_params)
        if result.success?
          render json: { token: result.data[:token], user: user_json(result.data[:user]) }, status: :created
        else
          render json: { errors: result.errors }, status: result.status
        end
      end

      # ログイン。メール・パスワード一致時に JWT を発行する。
      #
      # @return [void] 成功: `{ token:, user: }`（200）／失敗: `{ error: ... }`（401）
      def login
        result = AuthService.login(email: params[:email], password: params[:password])
        if result.success?
          render json: { token: result.data[:token], user: user_json(result.data[:user]) }
        else
          render json: { error: result.errors.first }, status: result.status
        end
      end

      private

      # Strong Parameters。登録フォームから受け取る許可カラムのみを抽出する。
      #
      # @return [ActionController::Parameters] name / email / password / password_confirmation
      def user_params
        params.require(:user).permit(:name, :email, :password, :password_confirmation)
      end

      # レスポンス用にユーザーの公開情報だけを整形する（password_digest 等は含めない）。
      #
      # @param user [User] 整形対象のユーザー
      # @return [Hash] `{ id:, name:, email: }`
      def user_json(user)
        { id: user.id, name: user.name, email: user.email }
      end
    end
  end
end
