module Api
  module V1
    # プロジェクトの CRUD エンドポイント。ロジックは ProjectService に委譲し、
    # 認可スコープ・404 もサービス + 基底の rescue_from に委ねる。
    class ProjectsController < ApplicationController
      # プロジェクト一覧を返す。
      #
      # @return [void] current_user のプロジェクト配列を JSON で render（200）
      def index
        render json: ProjectService.list(current_user)
      end

      # プロジェクト詳細を返す。
      #
      # @return [void] 取得したプロジェクトを JSON で render（200）／不存在は 404
      def show
        render json: ProjectService.fetch(current_user, params[:id])
      end

      # プロジェクトを作成する。
      #
      # @return [void] 成功: 作成した Project（201）／失敗: `{ errors: [...] }`（422）
      def create
        render_result ProjectService.create(current_user, project_params)
      end

      # プロジェクトを更新する。
      #
      # @return [void] 成功: 更新後の Project（200）／失敗: `{ errors: [...] }`（422）／不存在は 404
      def update
        project = ProjectService.fetch(current_user, params[:id])
        render_result ProjectService.update(project, project_params)
      end

      # プロジェクトを削除する。
      #
      # @return [void] 成功: ボディ無しで 204／不存在は 404
      def destroy
        project = ProjectService.fetch(current_user, params[:id])
        render_result ProjectService.destroy(project)
      end

      private

      # Strong Parameters。プロジェクトの許可カラムのみを抽出する。
      #
      # @return [ActionController::Parameters] title / description
      def project_params
        params.require(:project).permit(:title, :description)
      end
    end
  end
end
