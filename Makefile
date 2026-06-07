# Rails Task Web App - 開発用タスクランナー
#
# 使い方:
#   make            # ヘルプ表示
#   make up         # PostgreSQL + MinIO 起動
#   make setup      # 依存インストール + DB 準備（既定アプリ）
#   make test       # RSpec 実行（既定アプリ）
#   make test-all   # 両アプリでテスト実行
#
# アプリ切り替え（既定は fullstack）:
#   make console APP=rails-task-api-web-app

# ---- 変数 ----------------------------------------------------------------
# APP: 単一アプリ向け target の対象（既定は fullstack。例: make test APP=$(API)）
FS      := rails-task-fullstack-web-app
API     := rails-task-api-web-app
APP     ?= $(FS)
APPS    := $(FS) $(API)
COMPOSE := docker compose

.DEFAULT_GOAL := help

# ---- ヘルプ --------------------------------------------------------------
.PHONY: help
help: ## このヘルプを表示
	@echo "Rails Task Web App - make targets"
	@echo ""
	@echo "対象アプリ (APP): $(APP)"
	@echo "切替例: make test APP=$(API)"
	@echo ""
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

# ---- 環境 / Docker -------------------------------------------------------
.PHONY: env
env: ## .env が無ければ .env.example から生成
	@test -f .env || (cp .env.example .env && echo "✓ .env を .env.example から作成しました（値を編集してください）")

.PHONY: up
up: env ## PostgreSQL + MinIO を起動（バックグラウンド）
	$(COMPOSE) up -d

.PHONY: down
down: ## コンテナを停止・削除
	$(COMPOSE) down

.PHONY: restart
restart: down up ## コンテナを再起動

.PHONY: ps
ps: ## コンテナの状態を表示
	$(COMPOSE) ps

.PHONY: logs
logs: ## コンテナのログを追従表示
	$(COMPOSE) logs -f

.PHONY: clean
clean: ## コンテナとボリューム（DB/MinIO データ）を削除
	$(COMPOSE) down -v

# ---- セットアップ --------------------------------------------------------
.PHONY: setup
setup: ## 依存インストール + DB 準備（APP 対象）
	cd $(APP) && bin/setup --skip-server

.PHONY: setup-all
setup-all: ## 両アプリをセットアップ
	@for app in $(APPS); do $(MAKE) setup APP=$$app; done

# ---- データベース --------------------------------------------------------
.PHONY: db-setup
db-setup: ## DB 作成 + マイグレーション（APP 対象）
	cd $(APP) && bin/rails db:create db:migrate

.PHONY: migrate
migrate: ## マイグレーション実行（APP 対象）
	cd $(APP) && bin/rails db:migrate

.PHONY: db-prepare
db-prepare: ## テスト用 DB を準備（APP 対象）
	cd $(APP) && bin/rails db:test:prepare

.PHONY: db-reset
db-reset: ## DB をリセット（drop → create → migrate, APP 対象）
	cd $(APP) && bin/rails db:drop db:create db:migrate

.PHONY: seed
seed: ## seed データ投入（APP 対象）
	cd $(APP) && bin/rails db:seed

# ---- 実行 ----------------------------------------------------------------
.PHONY: server
server: ## Rails サーバ起動（APP 対象, http://localhost:3000）
	cd $(APP) && bin/rails server

.PHONY: console
console: ## Rails コンソール起動（APP 対象）
	cd $(APP) && bin/rails console

# ---- テスト --------------------------------------------------------------
.PHONY: test
test: ## Minitest + RSpec（APP 対象）
	cd $(APP) && bin/rails test && bundle exec rspec

.PHONY: test-js
test-js: ## JS system spec（fullstack のみ, 要 Chrome）
	cd $(FS) && bundle exec rspec --tag js

.PHONY: test-all
test-all: ## 両アプリでテスト実行
	@for app in $(APPS); do $(MAKE) test APP=$$app; done

# ---- 品質チェック --------------------------------------------------------
.PHONY: lint
lint: ## RuboCop 実行（APP 対象）
	cd $(APP) && bin/rubocop

.PHONY: lint-fix
lint-fix: ## RuboCop 自動修正（APP 対象）
	cd $(APP) && bin/rubocop -A

.PHONY: security
security: ## Brakeman + bundler-audit（APP 対象）
	cd $(APP) && bin/bundler-audit && bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error

.PHONY: ci
ci: ## ローカル CI 一括実行（APP 対象, bin/ci 相当）
	cd $(APP) && bin/ci

.PHONY: ci-all
ci-all: ## 両アプリでローカル CI 実行
	@for app in $(APPS); do $(MAKE) ci APP=$$app; done
