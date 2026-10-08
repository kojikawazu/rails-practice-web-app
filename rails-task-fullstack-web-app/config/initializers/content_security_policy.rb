# Be sure to restart your server when you modify this file.

# アプリ全体の Content Security Policy（CSP）。
# XSS 対策の多層防御（入力検証 + 出力エスケープ + CSP）のうち、**ブラウザ側の最終防御**を担う。
# 特に確認画面は利用者が入力した preview_url を iframe に埋め込むため、
# モデルの URL 検証と sandbox に加えて、ブラウザ側でも実行可能な資源を限定する。
#
# unsafe-inline はどのディレクティブにも許可しない。インライン JS は Stimulus へ、
# インライン style 属性は application.css のクラスへ移行済み（#101）。
Rails.application.configure do
  # development の Active Storage は MinIO（別オリジン）へリダイレクトするため、
  # blob の配信元を img-src に許可する。production は Disk（同一オリジン）配信のため不要。
  storage_image_origins = Rails.env.development? ? [ ENV.fetch("MINIO_ENDPOINT", "http://localhost:9000") ] : []

  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    policy.img_src     :self, :data, *storage_image_origins
    policy.object_src  :none
    policy.base_uri    :self
    policy.form_action :self
    # 自アプリを他サイトへ埋め込ませない（クリックジャッキング対策）。
    policy.frame_ancestors :none
    policy.connect_src :self

    # インライン JS は許可しない。importmap / Turbo のインライン script には
    # nonce が自動付与される（importmap-rails が content_security_policy_nonce を渡す）。
    policy.script_src :self

    # CSS は自オリジンのみ。style_src_attr を指定しないため、style 属性も style_src に従い拒否される
    # （View では style 属性を使わない。spec/requests/security_headers_spec.rb で検査する）。
    policy.style_src :self

    # タスクの preview_url プレビュー用。任意の外部サイトを埋め込むため http/https を許可し、
    # javascript: / data: スキームの frame は拒否する。埋め込みの封じ込めは
    # iframe の sandbox 属性とモデルの URL 検証が担う（06-security-specification.md）。
    policy.frame_src :http, :https
  end

  # nonce はレスポンスごとに使い捨てる（推測されると script-src の制限を回避されるため）。
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end
