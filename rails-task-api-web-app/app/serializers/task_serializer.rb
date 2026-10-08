# タスクのレスポンス整形。公開属性は docs/07-api-specification.md の契約に合わせる。
class TaskSerializer < ApplicationSerializer
  # API に公開するタスクの属性（ここに無いカラムはレスポンスに出ない）。
  # status は enum のため、整数ではなく "not_started" などの文字列で返る。
  ATTRIBUTES = %i[id title status due_date project_id created_at updated_at].freeze
end
