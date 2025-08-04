Sentry.init do |config|
  next if Rails.env.local?

  config.dsn = ""
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  config.traces_sample_rate = 1.0
end
