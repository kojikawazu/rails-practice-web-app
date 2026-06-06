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
    @project = current_user.projects.build
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

  # 確認画面の表示。DB には保存せず valid? で検証のみ行う。
  # id 有無で新規(build)／編集(find)を切り替える。
  def confirm
    @project = params[:id] ? current_user.projects.find(params[:id]) : current_user.projects.build
    @project.assign_attributes(project_params)

    # 確認画面の「修正する」押下時は入力フォームへ戻す（入力値は保持）。
    return render(@project.persisted? ? :edit : :new) if params[:back].present?

    if @project.valid?
      render :confirm
    else
      render(@project.persisted? ? :edit : :new, status: :unprocessable_entity)
    end
  end

  def create
    @project = current_user.projects.build(project_params)

    if @project.save
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

  def set_project
    @project = current_user.projects.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:title, :description)
  end
end
