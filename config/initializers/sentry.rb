Sentry.init do |config|
  next unless Rails.env.production?

  config.dsn = ""
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  config.traces_sample_rate = 1.0
end
