# タスクの一覧取得・生成・削除を担うサービス。
# create/update の save は画像添付（attach_signed_images）と app_host 設定を
# build と save の間に挟む必要があるため、あえて Controller に残す
# （save を本サービスへ移すと Active Storage が漏れ出し「画像ロジックは Controller」の方針に反する）。
# 認可スコープ（他ユーザーは 404）は Controller の set_project / set_task が担う。
class TaskService
  # プロジェクト配下のタスク一覧を返す。
  #
  # @param project [Project] 親プロジェクト（Controller が set_project で取得済み）
  # @return [ActiveRecord::Relation<Task>] タスク一覧
  def self.list(project) = project.tasks

  # 新規タスクを未保存で組み立てる（app_host 設定・画像添付・save は Controller が行う）。
  #
  # @param project [Project] 親プロジェクト
  # @param params [ActionController::Parameters, Hash] title / status / start_date / end_date / preview_url
  # @return [Task] 未保存の Task
  def self.build(project, params) = project.tasks.build(params)

  # タスクを削除する。
  #
  # @param task [Task] 削除対象
  # @return [void]
  def self.destroy(task) = task.destroy!
end
