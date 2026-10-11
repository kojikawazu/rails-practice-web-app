# エラーレスポンスの整形。API が返すすべてのエラーを `{ error: { code:, message:, details: } }` の
# 1 形態にする（#147。docs/07-api-specification.md「エラーハンドリング」）。
#
# - code は機械可読な契約で、クライアントはこれで分岐する。message は人に見せるだけで、変えても互換を壊さない。
# - details はバリデーションの内訳を渡すときだけ付け、それ以外はキーごと省く（null を返さない）。
# - HTTP ステータスは code から決める。Service は失敗の理由（code）だけを返し、HTTP への変換はここに集約する。
#   code とステータスを別々に渡させないことで、「not_found なのに 422」のような食い違いを作れなくする。
#
# レコードを公開属性に詰め直す ApplicationSerializer とは整形の対象が違うため、継承しない。
class ErrorSerializer
  # code ごとの HTTP ステータスと既定の message。取り得る code はこの一覧に閉じる。
  DEFINITIONS = {
    bad_request: { status: :bad_request, message: "Bad request" },
    unauthorized: { status: :unauthorized, message: "Unauthorized" },
    # メール不在とパスワード誤りを区別しない統一メッセージ（列挙攻撃対策。AuthService.login）。
    invalid_credentials: { status: :unauthorized, message: "メールアドレスまたはパスワードが正しくありません。" },
    not_found: { status: :not_found, message: "Not found" },
    validation_failed: { status: :unprocessable_content, message: "入力内容に誤りがあります" },
    rate_limited: { status: :too_many_requests, message: "Too many requests" },
    internal_error: { status: :internal_server_error, message: "Internal server error" }
  }.freeze
  private_constant :DEFINITIONS

  # エラーレスポンスのボディを組み立てる。
  #
  # @param code [Symbol] DEFINITIONS のキー
  # @param message [String, nil] 既定の message を差し替える場合に渡す（例: "Project not found"）
  # @param details [Array<String>, nil] バリデーションの内訳。空なら details キーを付けない
  # @return [Hash{Symbol => Hash}] `{ error: { code:, message:, details: } }`
  # @raise [ArgumentError] 一覧に無い code（仕様外の code を返さないため）
  def self.render(code, message: nil, details: nil)
    error = { code: code.to_s, message: message || definition(code)[:message] }
    error[:details] = details if details.present?
    { error: error }
  end

  # code に対応する HTTP ステータスを返す。
  #
  # @param code [Symbol] DEFINITIONS のキー
  # @return [Symbol] render に渡す HTTP ステータス
  # @raise [ArgumentError] 一覧に無い code
  def self.status_for(code)
    definition(code)[:status]
  end

  # @param code [Symbol] DEFINITIONS のキー
  # @return [Hash{Symbol => Object}] status と message
  # @raise [ArgumentError] 一覧に無い code
  def self.definition(code)
    DEFINITIONS.fetch(code) { raise ArgumentError, "unknown error code: #{code.inspect}" }
  end
  private_class_method :definition
end
