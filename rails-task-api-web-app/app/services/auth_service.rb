# 認証（ユーザー登録・ログイン・トークンの検証・ログアウト）のビジネスロジックを担うサービス。
# signup / login は成功時に user と発行した JWT を Result の data に格納して返す。
class AuthService < ApplicationService
  # Bearer トークンを検証し、トークンの持ち主のユーザーを確定する。
  #
  # 署名と有効期限は JsonWebToken.decode が見る。ここではそれに加えて、ログアウトで失効させた
  # トークン（RevokedToken）を拒否する。JWT だけでは発行済みのトークンを期限前に無効にできないため、
  # 失効の照合はサーバー側の状態を引くことになる（ステートレスであることとの引き換え）。
  #
  # jti / exp を持たないトークンは拒否する。jti が無いと失効させられず、exp が無いと失効の記録を
  # いつまで残すかを決められないため、ログアウトしても使い続けられるトークンを作らない。
  # 失敗の理由はすべて unauthorized にまとめ、失効済みかどうかを応答から区別させない。
  #
  # @param token [String, nil] Authorization ヘッダーから取り出した Bearer トークン
  # @return [ApplicationService::Result] 成功: data={ user:, claims: }（claims は logout に渡す）／失敗: code=:unauthorized
  def self.authenticate(token)
    claims = JsonWebToken.decode(token)
    return failure(code: :unauthorized) unless claims && claims[:jti].present? && claims[:exp].present?
    return failure(code: :unauthorized) if RevokedToken.exists?(jti: claims[:jti])

    user = User.find_by(id: claims[:user_id])
    return failure(code: :unauthorized) unless user

    success(data: { user: user, claims: claims })
  end

  # トークンを失効させる（その端末だけのログアウト）。同じユーザーの別のトークンは有効のまま残る。
  #
  # 呼び出しの前提: claims は authenticate が成功して返したもの（署名・有効期限・失効済みでないことを
  # 確認済み）を渡す。ここでは検証し直さないため、検証前のペイロードを渡すと任意の jti を失効させられる。
  #
  # 失効の記録はトークンの有効期限までしか意味を持たない（期限後は JWT の検証で弾かれる）。
  # 掃除のためのジョブ基盤を持たないので、ログアウトのたびに期限切れの行を消し、テーブルの大きさを
  # 「直近の有効期限内にログアウトされた数」に抑える。
  #
  # 記録は insert（ON CONFLICT (jti) DO NOTHING）で行う。同じトークンで同時にログアウトされると、
  # どちらも authenticate を通過した後で記録が衝突する。create! / create_or_find_by! では、
  # 先に走るモデルの uniqueness 検証が RecordInvalid を投げて 500 になるため使わない。
  # insert は検証を通らないが、値は authenticate で検証済みのクレームから作り、DB の NOT NULL と
  # 一意インデックスが最終的な制約になる。created_at / updated_at は insert でも自動で入る。
  #
  # @param claims [HashWithIndifferentAccess] authenticate が返したトークンのクレーム（jti / exp を含む）
  # @return [ApplicationService::Result] 成功（204）
  def self.logout(claims)
    RevokedToken.expired.delete_all
    RevokedToken.insert({ jti: claims[:jti], expires_at: Time.zone.at(claims[:exp]) }, unique_by: :jti)

    success(status: :no_content)
  end

  # ユーザーを新規登録し、成功時に JWT を発行する。
  #
  # @param params [ActionController::Parameters, Hash] name/email/password/password_confirmation
  # @return [ApplicationService::Result] 成功: data={ user:, token: }（201）／失敗: code=:validation_failed, errors=full_messages
  def self.signup(params)
    user = User.new(params)
    return failure(errors: user.errors.full_messages) unless user.save

    success(data: { user: user, token: JsonWebToken.encode(user_id: user.id) }, status: :created)
  end

  # メールアドレスとパスワードを検証し、成功時に JWT を発行する。
  # メール不在・パスワード誤りは区別せず、同じ理由（invalid_credentials）で失敗させる（列挙攻撃対策）。
  # 利用者に見せる統一メッセージは ErrorSerializer の invalid_credentials が持つ。
  #
  # @param email [String] メールアドレス
  # @param password [String] 平文パスワード
  # @return [ApplicationService::Result] 成功: data={ user:, token: }（200）／失敗: code=:invalid_credentials
  def self.login(email:, password:)
    user = User.find_by(email: email)
    if user&.authenticate(password)
      success(data: { user: user, token: JsonWebToken.encode(user_id: user.id) })
    else
      failure(code: :invalid_credentials)
    end
  end
end
