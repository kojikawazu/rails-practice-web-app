# サービス層の基底クラス。ビジネスロジックを Controller から切り離して集約する場所。
# 各サービスの成否は Result 値オブジェクトで表現し、Controller はそれを見て render を分岐する。
#
# 「他人の/存在しないリソース」による 404 は横断的な例外として ApplicationController の
# rescue_from に委ねるため、ここでは扱わない（検証失敗 422・認証失敗 401 のみ Result で表す）。
class ApplicationService
  # サービスの実行結果。成功可否・データ・エラー・HTTP ステータスを保持する。
  #
  # @!attribute [rw] success
  #   @return [Boolean] 成功なら true
  # @!attribute [rw] data
  #   @return [Object, nil] 成功時の戻り値（レコードやハッシュ）
  # @!attribute [rw] errors
  #   @return [Array<String>] 失敗時のエラーメッセージ配列
  # @!attribute [rw] status
  #   @return [Symbol] render に渡す HTTP ステータス（例: :ok / :created / :unprocessable_entity）
  Result = Struct.new(:success, :data, :errors, :status, keyword_init: true) do
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
  # @param errors [Array<String>] エラーメッセージ配列（full_messages 相当）
  # @param status [Symbol] HTTP ステータス（既定 :unprocessable_entity）
  # @return [Result] 失敗結果
  def self.failure(errors:, status: :unprocessable_entity)
    Result.new(success: false, data: nil, errors: errors, status: status)
  end
end
