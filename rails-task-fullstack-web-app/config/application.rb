require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# .env はモノレポ直下（DB / MinIO の接続情報を両アプリ・docker-compose で共有）に置くため、
# アプリ root の親ディレクトリから明示的に読み込む（既存の ENV は上書きしない）。
if defined?(Dotenv)
  Dotenv.load(File.expand_path("../../.env", __dir__))
end

module RailsTaskFullstackWebApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # サムネイル生成は ImageMagick（mini_magick）を使う（この環境に libvips が無いため）。
    config.active_storage.variant_processor = :mini_magick
  end
end
