module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_user!

      def signup
        @user = User.new(user_params)
        if @user.save
          token = JsonWebToken.encode(user_id: @user.id)
          render json: { token: token, user: user_json(@user) }, status: :created
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def login
        user = User.find_by(email: params[:email])
        if user&.authenticate(params[:password])
          token = JsonWebToken.encode(user_id: user.id)
          render json: { token: token, user: user_json(user) }
        else
          render json: { error: "メールアドレスまたはパスワードが正しくありません。" }, status: :unauthorized
        end
      end

      private

      def user_params
        params.require(:user).permit(:name, :email, :password, :password_confirmation)
      end

      def user_json(user)
        { id: user.id, name: user.name, email: user.email }
      end
    end
  end
end
