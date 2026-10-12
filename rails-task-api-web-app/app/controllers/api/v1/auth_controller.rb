module Api
  module V1
    # 認証エンドポイント（ユーザー登録・ログイン・ログアウト）。ロジックは AuthService に委譲し、
    # ここでは Strong Parameters とレスポンス整形（token + UserSerializer）に専念する。
    # signup / login は認証前でも叩けるよう、基底の authenticate_user! をスキップする。
    # logout は失効させるトークンそのものを認証に使うため、スキップしない。スキップは only で
    # 列挙する（except にすると、後から足したアクションが黙って認証なしで公開されるため）。
    #
    # login（パスワードの総当たり）と signup（アカウントの大量作成）には、API 全体より厳しい
    # レートリミットを掛ける（.claude/rules/security.md）。目的が違うため name でカウンタを分け、
    # 登録の失敗でログインまで止まらないようにする。単位は IP のみとし、メールアドレス単位にはしない
    # （他人のアドレスで上限まで失敗させ、その利用者をログインできなくする DoS を避けるため）。
    class AuthController < ApplicationController
      skip_before_action :authenticate_user!, only: %i[signup login]

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

      # ログアウト。認証に使ったトークンを失効させ、以降は同じトークンを 401 にする。
      # 同じユーザーの別のトークン（別の端末）は有効のまま残る。失効済みのトークンでの再実行は
      # authenticate_user! で 401 になる（失効済みかどうかを、ほかの無効なトークンと区別させない）。
      #
      # @return [void] 成功: ボディ無しの 204／トークンが無効: code: unauthorized（401）
      def logout
        render_result(AuthService.logout(current_token_claims))
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
