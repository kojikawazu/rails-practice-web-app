# ユーザー登録（サインアップ）を扱うコントローラー。
# 登録は「入力 → 確認 → 確定」の 3 ステップで、確認画面では DB に保存せず検証のみ行う。
class UsersController < ApplicationController
  # 登録フォームを表示する。
  #
  # @return [void] 空の @user で new ビューを描画
  def new
    @user = User.new
  end

  # 確認画面の表示。DB には保存せず valid? で検証のみ行う。
  #
  # @return [void] 検証成功: confirm ／「修正する」: new ／検証失敗: new（422）
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

  # 登録の確定。DB へ保存し、成功時はそのままログイン状態にする。
  #
  # @return [void] 成功: プロジェクト一覧へリダイレクト／失敗: new を 422 で再描画
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

  # Strong Parameters。登録フォームの許可カラムのみを抽出する。
  #
  # @return [ActionController::Parameters] name / email / password / password_confirmation
  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
