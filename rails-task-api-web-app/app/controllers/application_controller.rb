class ApplicationController < ActionController::API
  before_action :authenticate_user!

  private

  def authenticate_user!
    token = request.headers["Authorization"]&.split(" ")&.last
    decoded = JsonWebToken.decode(token)

    if decoded
      @current_user = User.find_by(id: decoded[:user_id])
    end

    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
  end

  def current_user
    @current_user
  end
end
