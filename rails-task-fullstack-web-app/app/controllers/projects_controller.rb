class ProjectsController < ApplicationController
  before_action :require_login
  before_action :set_project, only: %i[show edit update destroy]

  def index
    @projects = current_user.projects
  end

  def show
    @tasks = @project.tasks
  end

  def new
    # 「修正する」(restore=1) 経由は session の入力値を復元、通常の新規は session を破棄して空フォーム。
    if params[:restore].present?
      @project = current_user.projects.build(pending_project_params)
    else
      reset_pending_project
      @project = current_user.projects.build
    end
  end

  def edit
  end

  # 複製。複製元の値を初期入力した新規作成フォームを表示する（DB は変更しない）。
  # 以降は通常の confirm → create フローに合流する。
  def duplicate
    source = current_user.projects.find(params[:id])
    @project = current_user.projects.build(title: "#{source.title}のコピー", description: source.description)
    flash.now[:notice] = "「#{source.title}」を複製しました。内容を確認して作成してください。"
    render :new
  end

  # 確認画面。DB には保存せず検証のみ行う。
  # - 新規: (b案2) リダイレクト方式。confirm_new に委譲。
  # - 編集: 従来の POST 描画方式（変更なし）。
  def confirm
    return confirm_new unless params[:id]

    @project = current_user.projects.find(params[:id])
    @project.assign_attributes(project_params)

    # 確認画面の「修正する」押下時は入力フォームへ戻す（入力値は保持）。
    return render(:edit) if params[:back].present?

    if @project.valid?
      render :confirm
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    @project = current_user.projects.build(project_params)

    if @project.save
      reset_pending_project
      redirect_to @project, notice: "プロジェクトを作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: "プロジェクトを更新しました。", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy!
    redirect_to projects_path, notice: "プロジェクトを削除しました。", status: :see_other
  end

  private

  # 新規プロジェクトの確認画面（(b案2) リダイレクト方式 / PRG）。
  # POST: 検証 → 入力値を session に退避 → confirm(GET) へ 303 リダイレクト（Turbo Drive 対応）。
  # GET : session から復元して確認画面を描画。session が無ければ new へ戻す（リロード安全網）。
  def confirm_new
    if request.get?
      return redirect_to(new_project_path, alert: "確認画面の情報がありません。入力し直してください。") if pending_project_params.blank?

      @project = current_user.projects.build(pending_project_params)
      return render :confirm
    end

    @project = current_user.projects.build(project_params)
    if @project.valid?
      session[:pending_project] = project_params.to_h
      redirect_to confirm_projects_path, status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  # session に退避した新規プロジェクトの入力値（許可カラムのみ）。
  def pending_project_params
    (session[:pending_project] || {}).slice("title", "description")
  end

  def reset_pending_project
    session.delete(:pending_project)
  end

  def set_project
    @project = current_user.projects.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:title, :description)
  end
end
