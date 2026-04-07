# テスト仕様書（Test Specification）

## テスト戦略

学習目的のため、以下の2レベルに絞る:

| レベル | 目的 | 対象 |
|--------|------|------|
| Model spec | バリデーション・関連付けの検証 | User, Project, Task |
| Request spec | エンドポイントの動作検証 | 各CRUDアクション |

## テスト環境

- テスト用DB: PostgreSQL（`rails_task_test` データベース）
- Docker の PostgreSQL コンテナを開発用・テスト用で共有する
- `database.yml` の test 環境で別データベース名を指定
- テスト実行前に `rails db:test:prepare` でスキーマ同期

## テストケース

### Model spec

| モデル | テスト内容 |
|--------|-----------|
| User | 有効なデータで作成できる / name必須 / email必須・一意・形式 / password最小文字数 |
| Project | 有効なデータで作成できる / title必須 / user関連付け / 削除時にtasksも削除 |
| Task | 有効なデータで作成できる / title必須 / status必須・値の制限 / project関連付け |

### Request spec

| 対象 | テスト内容 |
|------|-----------|
| Projects | index/show/create/update/destroy の正常系 / 未ログイン時のリダイレクト |
| Tasks | index/show/create/update/destroy の正常系 / 存在しないprojectでの404 |
| Sessions | ログイン成功/失敗 / ログアウト |

## カバレッジ目標

- トレーニング目的のため、厳密なカバレッジ目標は設けない
- 主要なバリデーションと正常系CRUDを網羅することを目標とする

## テストツール

| ツール | 用途 |
|--------|------|
| RSpec | テストフレームワーク |
| FactoryBot | テストデータ生成 |
| Shoulda Matchers | バリデーション・関連付けのマッチャー |
| DatabaseCleaner | テスト間のDBクリーンアップ |
