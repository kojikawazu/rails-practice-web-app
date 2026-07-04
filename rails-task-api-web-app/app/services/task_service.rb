# タスクの取得・CRUD ロジックを担うサービス。
# 親プロジェクトを current_user 経由で、タスクをそのプロジェクト経由で取得することで
# 認可スコープ（他ユーザーのリソースは 404）を担保する。
# 取得はレコード/リレーションを直接返し、変更操作は成否を Result で返す。
class TaskService < ApplicationService
  # current_user の親プロジェクトを取得する（他ユーザー・不存在は例外）。
  #
  # @param user [User] 認証済みユーザー
  # @param project_id [String, Integer] 親プロジェクト id
  # @return [Project] 親プロジェクト
  # @raise [ActiveRecord::RecordNotFound] 他ユーザー・不存在（→404 "Project not found"）
  def self.fetch_project(user, project_id) = user.projects.find(project_id)

  # プロジェクト配下のタスクを 1 件取得する（不存在は例外）。
  #
  # @param project [Project] 親プロジェクト
  # @param task_id [String, Integer] タスク id
  # @return [Task] 取得したタスク
  # @raise [ActiveRecord::RecordNotFound] 不存在（→404 "Task not found"）
  def self.fetch_task(project, task_id) = project.tasks.find(task_id)

  # プロジェクト配下のタスク一覧を返す。
  #
  # @param project [Project] 親プロジェクト
  # @return [ActiveRecord::Relation] タスク一覧
  def self.list(project) = project.tasks

  # タスクを作成する。
  #
  # @param project [Project] 親プロジェクト
  # @param params [ActionController::Parameters, Hash] title / status / due_date
  # @return [ApplicationService::Result] 成功: data=Task（201）／失敗: errors=full_messages（422）
  def self.create(project, params)
    task = project.tasks.build(params)
    task.save ? success(data: task, status: :created) : failure(errors: task.errors.full_messages)
  end

  # タスクを更新する。
  #
  # @param task [Task] 更新対象
  # @param params [ActionController::Parameters, Hash] title / status / due_date
  # @return [ApplicationService::Result] 成功: data=Task（200）／失敗: errors=full_messages（422）
  def self.update(task, params)
    task.update(params) ? success(data: task) : failure(errors: task.errors.full_messages)
  end

  # タスクを削除する。
  #
  # @param task [Task] 削除対象
  # @return [ApplicationService::Result] 成功: 204（ボディ無し）
  def self.destroy(task)
    task.destroy
    success(status: :no_content)
  end
end
