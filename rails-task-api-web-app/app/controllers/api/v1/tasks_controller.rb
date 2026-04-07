module Api
  module V1
    class TasksController < ApplicationController
      before_action :set_project
      before_action :set_task, only: %i[show update destroy]

      def index
        @tasks = @project.tasks
        render json: @tasks
      end

      def show
        render json: @task
      end

      def create
        @task = @project.tasks.build(task_params)
        if @task.save
          render json: @task, status: :created
        else
          render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @task.update(task_params)
          render json: @task
        else
          render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @task.destroy
        head :no_content
      end

      private

      def set_project
        @project = current_user.projects.find(params[:project_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Project not found" }, status: :not_found
      end

      def set_task
        @task = @project.tasks.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Task not found" }, status: :not_found
      end

      def task_params
        params.require(:task).permit(:title, :status, :due_date)
      end
    end
  end
end
