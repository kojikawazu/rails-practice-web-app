# 全 ActiveRecord モデルの抽象基底クラス（Rails 標準）。
# アプリ共通のモデル設定を集約する場所として用いる。
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
