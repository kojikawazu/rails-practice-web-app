module Api
  module V1
    # タスクの CRUD エンドポイント。projects 配下のネストルーティングで、
    # 常に current_user のプロジェクトに属するタスクのみを操作する。
    class TasksController < ApplicationController
      before_action :set_project
      before_action :set_task, only: %i[show update destroy]

      # 親プロジェクトのタスク一覧を返す。
      #
      # @return [void] @project.tasks を JSON で render（200）
      def index
        @tasks = @project.tasks
        render json: @tasks
      end

      # タスク詳細を返す。
      #
      # @return [void] @task を JSON で render（200）
      def show
        render json: @task
      end

      # タスクを作成する。
      #
      # @return [void] 成功: 作成した Task（201）／失敗: `{ errors: [...] }`（422）
      def create
        @task = @project.tasks.build(task_params)
        if @task.save
          render json: @task, status: :created
        else
          render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # タスクを更新する。
      #
      # @return [void] 成功: 更新後の Task（200）／失敗: `{ errors: [...] }`（422）
      def update
        if @task.update(task_params)
          render json: @task
        else
          render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # タスクを削除する。
      #
      # @return [void] ボディ無しで 204 を返す
      def destroy
        @task.destroy
        head :no_content
      end

      private

      # URL の :project_id から current_user のプロジェクトを取得して @project に設定する。
      # 他ユーザー・存在しない id は 404 を返して処理を中断する。
      #
      # @return [void] 見つからない場合は `{ error: "Project not found" }`（404）
      def set_project
        @project = current_user.projects.find(params[:project_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Project not found" }, status: :not_found
      end

      # URL の :id から @project 配下のタスクを取得して @task に設定する。
      # 存在しない id は 404 を返して処理を中断する。
      #
      # @return [void] 見つからない場合は `{ error: "Task not found" }`（404）
      def set_task
        @task = @project.tasks.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Task not found" }, status: :not_found
      end

      # Strong Parameters。タスクの許可カラムのみを抽出する。
      # API 版は期日を単一の due_date で持つ（フルスタック版の start_date/end_date とは意図的に異なる）。
      #
      # @return [ActionController::Parameters] title / status / due_date
      def task_params
        params.require(:task).permit(:title, :status, :due_date)
      end
    end
  end
end
