class TasksController < ApplicationController
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
    @project = Project.find(params[:project_id])
  end

  def set_task
    @task = @project.tasks.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :status, :due_date)
  end
end
