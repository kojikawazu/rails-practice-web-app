# プロジェクトの取得・CRUD ロジックを担うサービス。
# 取得はレコード/リレーションを直接返し（唯一の失敗＝not_found は例外→404）、
# 変更操作（create/update/destroy）は成否を Result で返す。
# 認可スコープ（current_user のプロジェクトに限定）はここで担保する。
class ProjectService < ApplicationService
  # current_user のプロジェクト一覧を返す。
  #
  # @param user [User] 認証済みユーザー
  # @return [ActiveRecord::Relation] user のプロジェクト
  def self.list(user) = user.projects

  # current_user のプロジェクトを 1 件取得する（他ユーザー・不存在は例外）。
  #
  # @param user [User] 認証済みユーザー
  # @param id [String, Integer] プロジェクト id
  # @return [Project] 取得したプロジェクト
  # @raise [ActiveRecord::RecordNotFound] 他ユーザーのリソース・存在しない id（→404）
  def self.fetch(user, id) = user.projects.find(id)

  # プロジェクトを作成する。
  #
  # @param user [User] 認証済みユーザー
  # @param params [ActionController::Parameters, Hash] title / description
  # @return [ApplicationService::Result] 成功: data=Project（201）／失敗: errors=full_messages（422）
  def self.create(user, params)
    project = user.projects.build(params)
    project.save ? success(data: project, status: :created) : failure(errors: project.errors.full_messages)
  end

  # プロジェクトを更新する。
  #
  # @param project [Project] 更新対象
  # @param params [ActionController::Parameters, Hash] title / description
  # @return [ApplicationService::Result] 成功: data=Project（200）／失敗: errors=full_messages（422）
  def self.update(project, params)
    project.update(params) ? success(data: project) : failure(errors: project.errors.full_messages)
  end

  # プロジェクトを削除する（配下のタスクも連動削除）。
  #
  # @param project [Project] 削除対象
  # @return [ApplicationService::Result] 成功: 204（ボディ無し）
  def self.destroy(project)
    project.destroy
    success(status: :no_content)
  end
end
