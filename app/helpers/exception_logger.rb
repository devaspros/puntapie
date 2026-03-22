# frozen_string_literal: true

# Sends exceptions with stack traces to Sentry while logging the provided message to the logs.
class ExceptionLogger
  def self.log(exception, log_message, **sentry_options)
    Rails.logger.error(log_message)

    begin
      raise exception, exception.message, exception.backtrace
    rescue exception.class => e
      Sentry.capture_exception(e, level: "error", **sentry_options)
    end
  end
end
