# プロジェクトの一覧取得・CRUD ロジックを担うサービス。
# 検証失敗時もレコードを返し、Controller が errors でフォームを再描画できるようにする
# （フルスタック版は HTML 再描画のため Result 値オブジェクトを使わない）。
# 認可スコープ（他ユーザーは 404）は Controller の set_project が担う（本サービスは扱わない）。
class ProjectService
  # current_user のプロジェクト一覧を返す。
  #
  # @param user [User] 認証済みユーザー
  # @return [ActiveRecord::Relation<Project>] user のプロジェクト
  def self.list(user) = user.projects

  # プロジェクトを作成する（保存の成否に関わらずレコードを返す）。
  #
  # @param user [User] 認証済みユーザー
  # @param params [ActionController::Parameters, Hash] title / description
  # @return [Project] persisted? == true または errors を保持したレコード
  def self.create(user, params) = user.projects.build(params).tap(&:save)

  # プロジェクトを更新する。
  #
  # @param project [Project] 更新対象（Controller が set_project で取得済み）
  # @param params [ActionController::Parameters, Hash] title / description
  # @return [Boolean] 更新に成功したら true
  def self.update(project, params) = project.update(params)

  # プロジェクトを削除する（配下のタスクも連動削除）。
  #
  # @param project [Project] 削除対象
  # @return [void]
  def self.destroy(project) = project.destroy!
end
