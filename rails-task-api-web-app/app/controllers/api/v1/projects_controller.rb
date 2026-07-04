module Api
  module V1
    # プロジェクトの CRUD エンドポイント。操作対象は常に current_user のプロジェクトに限定する
    # （他ユーザーのリソースは set_project で 404 になる）。
    class ProjectsController < ApplicationController
      before_action :set_project, only: %i[show update destroy]

      # プロジェクト一覧を返す。
      #
      # @return [void] current_user のプロジェクト配列を JSON で render（200）
      def index
        @projects = current_user.projects
        render json: @projects
      end

      # プロジェクト詳細を返す。
      #
      # @return [void] @project を JSON で render（200）
      def show
        render json: @project
      end

      # プロジェクトを作成する。
      #
      # @return [void] 成功: 作成した Project（201）／失敗: `{ errors: [...] }`（422）
      def create
        @project = current_user.projects.build(project_params)
        if @project.save
          render json: @project, status: :created
        else
          render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # プロジェクトを更新する。
      #
      # @return [void] 成功: 更新後の Project（200）／失敗: `{ errors: [...] }`（422）
      def update
        if @project.update(project_params)
          render json: @project
        else
          render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # プロジェクトを削除する（紐づくタスクも dependent: :destroy で連動削除）。
      #
      # @return [void] ボディ無しで 204 を返す
      def destroy
        @project.destroy
        head :no_content
      end

      private

      # URL の :id から current_user のプロジェクトを取得して @project に設定する。
      # 他ユーザーのリソース・存在しない id は 404 を返して処理を中断する。
      #
      # @return [void] 見つからない場合は `{ error: "Project not found" }`（404）
      def set_project
        @project = current_user.projects.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Project not found" }, status: :not_found
      end

      # Strong Parameters。プロジェクトの許可カラムのみを抽出する。
      #
      # @return [ActionController::Parameters] title / description
      def project_params
        params.require(:project).permit(:title, :description)
      end
    end
  end
end
