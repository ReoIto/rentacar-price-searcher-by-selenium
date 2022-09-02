class Utility
  class << self
    def log_exception error, args
      Rails.logger.warn args[:info] if args[:info]
      Rails.logger.warn error.message
      Rails.logger.warn error.backtrace.join "\n"
    end
  end
end