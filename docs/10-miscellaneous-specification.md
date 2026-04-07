# その他仕様書（Miscellaneous Specification）

## 用語集

| 用語 | 説明 |
|------|------|
| scaffold | Railsのコード自動生成機能。Model/Controller/View/Migration/Routeを一括生成 |
| has_secure_password | Railsの認証ヘルパー。bcryptでパスワードをハッシュ化する |
| ERB | Embedded Ruby。HTMLにRubyコードを埋め込むテンプレートエンジン |
| Strong Parameters | マスアサインメント脆弱性を防ぐRailsの仕組み |
| ActiveRecord | RailsのORM。DBテーブルをRubyオブジェクトとしてアクセスする |
| Migration | DBスキーマの変更をRubyコードで管理する仕組み |
| docker-compose | 複数コンテナの定義・起動を管理するツール。今回はPostgreSQL用 |
| pg gem | RubyからPostgreSQLに接続するためのドライバ |
| database.yml | Railsのデータベース接続設定ファイル。環境ごとに設定を分ける |

## 参考資料

- [Ruby on Rails Guides](https://guides.rubyonrails.org/)
- [RSpec公式ドキュメント](https://rspec.info/)
- [PostgreSQL公式ドキュメント](https://www.postgresql.org/docs/)
- [Docker Compose公式ドキュメント](https://docs.docker.com/compose/)

## 付録

### フルスタック vs APIモード 比較

| 観点 | フルスタック | APIモード |
|------|-------------|-----------|
| View | ERBテンプレート | なし（JSON） |
| ミドルウェア | フルセット | API用に軽量化 |
| CSRF保護 | あり | なし（APIはトークン認証前提） |
| セッション | Cookie | 必要に応じて設定 |
| 学習目的 | Railsの規約を体感 | API設計パターンを理解 |
