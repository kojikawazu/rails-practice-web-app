class TasksController < ApplicationController
  before_action :require_login
  before_action :set_project
  before_action :set_task, only: %i[show edit update destroy]

  def index
    @tasks = @project.tasks

    respond_to do |format|
      format.html { redirect_to project_path(@project) }
      format.json { render :index }
    end
  end

  def show
  end

  def new
    @task = @project.tasks.build
  end

  def edit
  end

  # 複製。複製元の値を初期入力した新規作成フォームを表示する（DB は変更しない）。
  # 以降は通常の confirm → create フローに合流する（@project は set_project で取得済み）。
  def duplicate
    source = @project.tasks.find(params[:id])
    @task = @project.tasks.build(title: "#{source.title}のコピー", status: source.status, due_date: source.due_date)
    flash.now[:notice] = "「#{source.title}」を複製しました。内容を確認して作成してください。"
    render :new
  end

  # 確認画面の表示。DB には保存せず valid? で検証のみ行う。
  # id 有無で新規(build)／編集(find)を切り替える（@project は set_project で取得済み）。
  def confirm
    @task = params[:id] ? @project.tasks.find(params[:id]) : @project.tasks.build
    @task.assign_attributes(task_params)

    # 確認画面の「修正する」押下時は入力フォームへ戻す（入力値は保持）。
    return render(@task.persisted? ? :edit : :new) if params[:back].present?

    if @task.valid?
      render :confirm
    else
      render(@task.persisted? ? :edit : :new, status: :unprocessable_entity)
    end
  end

  def create
    @task = @project.tasks.build(task_params)

    if @task.save
      redirect_to project_path(@project), notice: "タスクを作成しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @task.update(task_params)
      redirect_to project_task_path(@project, @task), notice: "タスクを更新しました。", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy!
    redirect_to project_path(@project), notice: "タスクを削除しました。", status: :see_other
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_task
    @task = @project.tasks.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :status, :due_date)
  end
end
