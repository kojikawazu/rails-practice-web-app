# JWT（JSON Web Token）の発行・検証を担うユーティリティモジュール。
# API モードは Cookie/セッションを持たないため、認証はこのトークンで行う。
#
# @see Api::V1::AuthController トークンの発行元
# @see ApplicationController#authenticate_user! トークンの検証元
module JsonWebToken
  # 署名・検証に用いる秘密鍵（Rails の secret_key_base を流用）。
  SECRET_KEY = Rails.application.secret_key_base

  # ペイロードを署名付き JWT にエンコードする。
  #
  # @param payload [Hash] トークンに格納する任意のデータ（例: `{ user_id: 1 }`）
  # @param exp [ActiveSupport::TimeWithZone] 有効期限（既定は発行から 24 時間後）
  # @return [String] エンコード済みの JWT 文字列
  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  # JWT をデコードしてペイロードを取り出す。署名不正・期限切れ等では nil を返す。
  #
  # @param token [String, nil] `Authorization: Bearer` から取り出したトークン文字列
  # @return [HashWithIndifferentAccess, nil] デコード済みペイロード。検証失敗時は nil
  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY).first
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError
    nil
  end
end
