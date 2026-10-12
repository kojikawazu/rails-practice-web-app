# ログアウトで失効させた JWT の記録（denylist）。
#
# JWT は署名と有効期限だけで検証できる（ステートレス）ため、そのままでは発行済みのトークンを
# 期限前に無効にできない。失効させたトークンの jti をここに残し、認証のたびに照合する
# （AuthService.authenticate）。その代わり、リクエストごとに DB を 1 回引くことになる。
#
# 行はトークンの有効期限（expires_at）までしか意味を持たない。期限を過ぎたトークンは
# JWT の検証で弾かれるため、期限切れの行は AuthService.logout が消す。
#
# @!attribute [rw] jti
#   @return [String] 失効させたトークンの JWT ID（必須・一意）
# @!attribute [rw] expires_at
#   @return [ActiveSupport::TimeWithZone] 失効させたトークンの有効期限（JWT の exp）。必須
class RevokedToken < ApplicationRecord
  validates :jti, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :expired, -> { where(expires_at: ..Time.current) }
end
