# レスポンス整形の基底クラス。ActiveRecord を `render json:` へ直接渡さず、
# サブクラスが ATTRIBUTES で列挙した公開属性だけを Hash に詰め直す。
#
# `render json: record` は内部で `record.as_json` を呼び、全カラムを出力する。
# そのため「出さない属性」を後から除く denylist 方式では、カラム追加がそのまま API へ露出する。
# ここでは allowlist 方式を取り、API 契約（公開属性）と DB スキーマを切り離す。
#
# 変換は Controller で行い、Service はモデルを返したままにする（表現の判断を HTTP 層に残すため）。
class ApplicationSerializer
  # 単体のレコード、またはコレクションを JSON 化できる形に変換する。
  #
  # @param resource [ActiveRecord::Base, Enumerable<ActiveRecord::Base>] 変換対象
  # @return [Hash, Array<Hash>] 単体なら Hash、コレクションなら Hash の配列
  def self.render(resource)
    # ActiveRecord::Relation も to_ary に応答するため、配列とリレーションをまとめて扱える
    return resource.to_ary.map { |record| serialize(record) } if resource.respond_to?(:to_ary)

    serialize(resource)
  end

  # 1 レコードを公開属性だけの Hash にする。
  #
  # @param record [ActiveRecord::Base] 変換対象
  # @return [Hash{Symbol => Object}] ATTRIBUTES の各属性名と値
  def self.serialize(record)
    self::ATTRIBUTES.index_with { |attribute| record.public_send(attribute) }
  end
  private_class_method :serialize
end
