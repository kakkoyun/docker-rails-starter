require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DockerRailsStarter
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.generators do |g|
      g.assets false
      g.helper false
      g.stylesheets false
      g.javascripts false
      g.test_framework false
    end

    # NOTICE: Not include all helpers for all controller/views.
    config.action_controller.include_all_helpers = false

    # Active Job Configuration
    config.active_job.queue_adapter = :sidekiq

    # Enable/disable caching. By default caching is disabled.
    # .inquiry.true?
    if ActiveModel::Type::Boolean.new.cast(ENV['CACHE_ENABLED'])
      config.action_controller.perform_caching = true
      # Cache Store
      if ENV['REDIS_CACHE_URL']
        redis_uri = URI.parse URI.encode ENV['REDIS_CACHE_URL']
        config.cache_store = :redis_store, {
          host: redis_uri.host,
          port: redis_uri.port,
          db: ENV['REDIS_CACHE_DB'] || 1,
          # password: 'mysecret',
          namespace: ENV['REDIS_CACHE_NS'] || 'cache',
          expires_in: 240.minutes
        }
      end
    else
      config.action_controller.perform_caching = false
      config.cache_store = :null_store
    end
  end
end
