---
description: コーディング規約
globs: 
---

# コーディング規約

- **言語**: Ruby（Rails の規約に従う）
- **パッケージマネージャ**: Bundler を使用（gem のインストールは `bundle install`）
- **Linter / Formatter**: RuboCop でコード品質を担保
- **環境変数**: 設定値は環境変数で管理（.env）
- **シークレット禁止**: シークレット・認証情報をハードコードしない
