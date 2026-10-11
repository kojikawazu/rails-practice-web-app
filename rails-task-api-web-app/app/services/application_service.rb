# サービス層の基底クラス。ビジネスロジックを Controller から切り離して集約する場所。
# 各サービスの成否は Result 値オブジェクトで表現し、Controller はそれを見て render を分岐する。
#
# 「他人の/存在しないリソース」による 404 は横断的な例外として ApplicationController の
# rescue_from に委ねるため、ここでは扱わない（検証失敗・認証失敗のみ Result で表す）。
#
# 失敗は HTTP ステータスではなく理由（code）で表す。code から HTTP ステータス・レスポンスの形への
# 変換は HTTP 層（ErrorSerializer）が担い、Service は HTTP を知らない。
class ApplicationService
  # サービスの実行結果。成功可否・データ・成功時の HTTP ステータス・失敗の理由と内訳を保持する。
  #
  # @!attribute [rw] success
  #   @return [Boolean] 成功なら true
  # @!attribute [rw] data
  #   @return [Object, nil] 成功時の戻り値（レコードやハッシュ）
  # @!attribute [rw] errors
  #   @return [Array<String>] 失敗時の内訳（バリデーションの full_messages。無ければ空配列）
  # @!attribute [rw] status
  #   @return [Symbol, nil] 成功時に render へ渡す HTTP ステータス（例: :ok / :created / :no_content）。失敗時は nil
  # @!attribute [rw] code
  #   @return [Symbol, nil] 失敗の理由（ErrorSerializer の code。例: :validation_failed）。成功時は nil
  Result = Struct.new(:success, :data, :errors, :status, :code, keyword_init: true) do
    # @return [Boolean] 成功なら true
    def success? = success

    # @return [Boolean] 失敗なら true
    def failure? = !success
  end

  # 成功 Result を生成する。
  #
  # @param data [Object, nil] 成功時に返すデータ
  # @param status [Symbol] HTTP ステータス（既定 :ok）
  # @return [Result] 成功結果
  def self.success(data: nil, status: :ok)
    Result.new(success: true, data: data, errors: [], status: status)
  end

  # 失敗 Result を生成する。
  #
  # @param code [Symbol] 失敗の理由（ErrorSerializer の code。既定 :validation_failed）
  # @param errors [Array<String>] 内訳（バリデーションの full_messages 相当。既定は空）
  # @return [Result] 失敗結果
  def self.failure(code: :validation_failed, errors: [])
    Result.new(success: false, data: nil, errors: errors, code: code)
  end
end
