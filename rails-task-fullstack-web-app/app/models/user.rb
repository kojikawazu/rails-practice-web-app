# ユーザーモデル。has_secure_password でパスワードを bcrypt ハッシュ化して保持する。
# 1 ユーザーは複数のプロジェクトを持ち、削除時は配下のプロジェクトも連動削除される。
#
# @!attribute [rw] name
#   @return [String] ユーザー名（必須・最大 50 文字）
# @!attribute [rw] email
#   @return [String] メールアドレス（必須・一意・形式チェックあり）
# @!attribute [rw] password
#   @return [String] 平文パスワード（保存時に password_digest へハッシュ化。作成時は最小 6 文字）
class User < ApplicationRecord
  has_secure_password

  has_many :projects, dependent: :destroy

  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, on: :create
end
