# ユーザーのレスポンス整形。password_digest などの認証情報は公開しない。
class UserSerializer < ApplicationSerializer
  # API に公開するユーザーの属性（ここに無いカラムはレスポンスに出ない）。
  ATTRIBUTES = %i[id name email].freeze
end
