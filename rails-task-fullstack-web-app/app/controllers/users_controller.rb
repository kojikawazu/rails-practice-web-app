class UsersController < ApplicationController
  def new
    @user = User.new
  end

  # 確認画面の表示。DB には保存せず valid? で検証のみ行う。
  def confirm
    @user = User.new(user_params)

    # 確認画面の「修正する」押下時は入力フォームへ戻す（入力値は保持）。
    return render :new if params[:back].present?

    if @user.valid?
      render :confirm
    else
      render :new, status: :unprocessable_entity
    end
  end

  def create
    @user = User.new(user_params)

    if @user.save
      session[:user_id] = @user.id
      redirect_to projects_path, notice: "アカウントを作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
