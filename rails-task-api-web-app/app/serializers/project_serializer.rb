# プロジェクトのレスポンス整形。公開属性は docs/07-api-specification.md の契約に合わせる。
class ProjectSerializer < ApplicationSerializer
  # API に公開するプロジェクトの属性（ここに無いカラムはレスポンスに出ない）。
  ATTRIBUTES = %i[id title description user_id created_at updated_at].freeze
end
