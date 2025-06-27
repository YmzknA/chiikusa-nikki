require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Myapp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Configure Active Record encryption using Rails credentials
    if Rails.application.credentials.active_record_encryption.present?
      encryption_config = Rails.application.credentials.active_record_encryption
      config.active_record.encryption.primary_key = encryption_config.primary_key
      config.active_record.encryption.deterministic_key = encryption_config.deterministic_key
      config.active_record.encryption.key_derivation_salt = encryption_config.key_derivation_salt
    end

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Tokyo"
    config.i18n.default_locale = :ja
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
