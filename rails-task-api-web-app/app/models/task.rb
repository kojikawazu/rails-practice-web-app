# タスクモデル。プロジェクトに属する作業単位で、ステータスを enum で管理する。
# status は DB にデフォルトを持たないため、新規レコード時にコールバックで初期化する。
#
# @!attribute [rw] title
#   @return [String] タスク名（必須・最大 200 文字）
# @!attribute [rw] status
#   @return [String] ステータス（not_started / in_progress / completed。遷移は ALLOWED_STATUS_TRANSITIONS に従う）
class Task < ApplicationRecord
  # ステータスの初期値と、そこから許可する遷移
  # （docs/03-functional-specification.md のステータス遷移図を業務制約として扱う）。
  #
  # enum の値チェック（`validate: true`）は「3 値のどれか」しか見ないため、
  # 「今の状態から次の状態へ移ってよいか」は別に検証する。フォーム・API・コンソールの
  # どの入口から来ても同じ規則で守るため、Service ではなくモデルに置く。
  INITIAL_STATUS = "not_started".freeze
  ALLOWED_STATUS_TRANSITIONS = {
    "not_started" => %w[in_progress].freeze,
    "in_progress" => %w[completed].freeze,
    "completed" => %w[in_progress].freeze # 差し戻しのみ（not_started へは戻さない）
  }.freeze

  belongs_to :project

  enum :status, { not_started: 0, in_progress: 1, completed: 2 }, validate: true

  validates :title, presence: true, length: { maximum: 200 }

  validate :status_must_start_from_initial, on: :create
  validate :status_transition_must_be_allowed, on: :update

  after_initialize :set_default_status, if: :new_record?

  private

  # 新規レコードの status 未設定時に既定値（not_started）をセットする。
  # DB 側にデフォルトを持たせない代わりのアプリ層での初期化。
  #
  # @return [void]
  def set_default_status
    self.status ||= :not_started
  end

  # 新規作成時のステータスを初期値（not_started）に限定する。
  # 作成直後に completed を許すと遷移図が意味を失うため、作成も遷移規則の一部として扱う。
  #
  # @return [void] 違反時は errors に追加する
  def status_must_start_from_initial
    return if status == INITIAL_STATUS

    errors.add(:status, "は新規作成時 #{INITIAL_STATUS} のみ指定できます")
  end

  # 更新時のステータス変更が、許可された遷移かを検証する（ステータス未変更なら何もしない）。
  # 変更前の値は ActiveModel::Dirty の status_was（＝保存済みの状態）を使う。
  #
  # @return [void] 違反時は errors に追加する
  def status_transition_must_be_allowed
    return unless status_changed?

    allowed = ALLOWED_STATUS_TRANSITIONS.fetch(status_was, [])
    return if allowed.include?(status)

    errors.add(:status, "は #{status_was} から #{status} へは変更できません（許可: #{allowed.presence&.join(' / ') || 'なし'}）")
  end
end
