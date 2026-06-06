require "ipaddr"

class Task < ApplicationRecord
  # 画像添付の許可形式と上限サイズ（コントローラー側の事前チェックでも参照する）
  IMAGE_CONTENT_TYPES = %w[image/png image/jpeg image/gif image/webp].freeze
  MAX_IMAGE_SIZE = 5.megabytes

  # プレビュー URL の制約。iframe に渡るため http/https のみ許可し、
  # 内部/ループバックや自ホストの埋め込み（sandbox 脱獄経路）を拒否する。
  MAX_PREVIEW_URL_LENGTH = 2000
  BLOCKED_PREVIEW_HOSTS = %w[localhost 0.0.0.0].freeze

  # 確認画面/保存時にコントローラーが自アプリのホスト名を渡す（自オリジン埋め込みの拒否用）。
  attr_accessor :app_host

  belongs_to :project

  # 1タスクに複数の画像を添付できる（Active Storage）
  has_many_attached :images

  enum :status, { not_started: 0, in_progress: 1, completed: 2 }, validate: true

  after_initialize :set_default_status, if: :new_record?

  validates :title, presence: true, length: { maximum: 200 }

  validate :end_date_not_before_start_date
  validate :images_format_and_size
  validate :preview_url_must_be_http

  private

  def set_default_status
    self.status ||= :not_started
  end

  # 開始日・終了日が両方入力されている場合のみ、終了日 >= 開始日 を検証する。
  # （どちらも任意項目のため、片方のみ／未入力は許容する）
  def end_date_not_before_start_date
    return if start_date.blank? || end_date.blank?
    return if end_date >= start_date

    errors.add(:end_date, "は開始日以降の日付にしてください")
  end

  # 添付画像の形式・サイズを検証する（不正な添付はドメイン層で弾く）。
  def images_format_and_size
    images.each do |image|
      unless IMAGE_CONTENT_TYPES.include?(image.content_type)
        errors.add(:images, "は png / jpeg / gif / webp 形式のみ対応しています")
      end
      if image.byte_size > MAX_IMAGE_SIZE
        errors.add(:images, "は1枚あたり5MB以下にしてください")
      end
    end
  end

  # プレビュー URL を検証する（任意項目）。iframe の src に渡るため、
  # ① http/https 以外（javascript:/data:/file: 等）と不正形式を拒否、
  # ② localhost/内部IP/自ホストの埋め込み（allow-same-origin での脱獄経路）を拒否する。
  def preview_url_must_be_http
    return if preview_url.blank?

    if preview_url.length > MAX_PREVIEW_URL_LENGTH
      errors.add(:preview_url, "は#{MAX_PREVIEW_URL_LENGTH}文字以内で入力してください")
      return
    end

    uri = URI.parse(preview_url)
    unless uri.is_a?(URI::HTTP) && uri.host.present?
      errors.add(:preview_url, "は http:// または https:// で始まる URL を入力してください")
      return
    end

    if blocked_preview_host?(uri.host)
      errors.add(:preview_url, "は外部サイトの URL を指定してください（localhost・内部アドレス・自ホストは埋め込めません）")
    end
  rescue URI::InvalidURIError
    errors.add(:preview_url, "は正しい URL 形式で入力してください")
  end

  # 埋め込みを禁止するホストか判定する。
  # localhost 等・自アプリのホスト・ループバック/プライベート/リンクローカル IP を拒否。
  # IPv6 リテラルの角括弧（[::1]）と FQDN 末尾のドット（localhost.）を正規化してから判定し、
  # 表記揺れによるバイパスを防ぐ。
  def blocked_preview_host?(host)
    normalized = host.to_s.downcase.sub(/\A\[(.+)\]\z/, '\1').chomp(".")
    return true if BLOCKED_PREVIEW_HOSTS.include?(normalized)
    return true if app_host.present? && normalized == app_host.to_s.downcase.chomp(".")

    begin
      ip = IPAddr.new(normalized)
      ip.loopback? || ip.private? || ip.link_local?
    rescue IPAddr::InvalidAddressError
      false # ホスト名（IP でない）は IP ベースの遮断対象外
    end
  end
end
