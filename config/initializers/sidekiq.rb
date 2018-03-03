if ENV['REDIS_SIDEKIQ_URL']
  redis_uri = URI.parse URI.encode ENV['REDIS_SIDEKIQ_URL']
  redis = { host: redis_uri.host,
            port: redis_uri.port,
            db: ENV['REDIS_SIDEKIQ_DB'] || 0,
            network_timeout: 5 }
  Sidekiq.configure_server do |config|
    config.redis = redis
  end
  Sidekiq.configure_client do |config|
    config.redis = redis
  end
  Sidekiq::Logging.logger = Rails.logger
end
