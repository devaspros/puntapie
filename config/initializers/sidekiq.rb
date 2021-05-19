Sidekiq::Extensions.enable_delay! # About delayed extensions https://github.com/mperham/sidekiq/wiki/Delayed-extensions

SIDEKIQ_REDIS_CONFIGURATION = {
  url: ENV["REDIS_URL"],
  ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
}

Sidekiq.configure_server do |config|
  config.redis = SIDEKIQ_REDIS_CONFIGURATION
end

Sidekiq.configure_client do |config|
  config.redis = SIDEKIQ_REDIS_CONFIGURATION
end
