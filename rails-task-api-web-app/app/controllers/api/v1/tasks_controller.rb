module Api
  module V1
    # タスクの CRUD エンドポイント。projects 配下のネストルーティングで、
    # ロジックは TaskService に委譲する。認可スコープ・404 はサービス + 基底の rescue_from に委ねる。
    class TasksController < ApplicationController
      before_action :set_project

      # 親プロジェクトのタスク一覧を返す。
      #
      # @return [void] タスク一覧を JSON で render（200）
      def index
        render json: TaskService.list(@project)
      end

      # タスク詳細を返す。
      #
      # @return [void] 取得したタスクを JSON で render（200）／不存在は 404
      def show
        render json: TaskService.fetch_task(@project, params[:id])
      end

      # タスクを作成する。
      #
      # @return [void] 成功: 作成した Task（201）／失敗: `{ errors: [...] }`（422）
      def create
        render_result TaskService.create(@project, task_params)
      end

      # タスクを更新する。
      #
      # @return [void] 成功: 更新後の Task（200）／失敗: `{ errors: [...] }`（422）／不存在は 404
      def update
        task = TaskService.fetch_task(@project, params[:id])
        render_result TaskService.update(task, task_params)
      end

      # タスクを削除する。
      #
      # @return [void] 成功: ボディ無しで 204／不存在は 404
      def destroy
        task = TaskService.fetch_task(@project, params[:id])
        render_result TaskService.destroy(task)
      end

      private

      # URL の :project_id から current_user のプロジェクトを取得して @project に設定する。
      #
      # @return [void]
      # @raise [ActiveRecord::RecordNotFound] 他ユーザー・不存在（→404 "Project not found"）
      def set_project
        @project = TaskService.fetch_project(current_user, params[:project_id])
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
