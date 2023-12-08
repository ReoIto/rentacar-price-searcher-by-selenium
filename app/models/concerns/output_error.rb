module OutputError
  extend ActiveSupport::Concern

  included do
    # @param <ExceptionClass> error
    # @param <Hash> args
    def output_error(error, args)
      Rails.logger.warn args[:info] if args[:info]
      Rails.logger.warn error.message
      Rails.logger.warn error.backtrace.join "\n"
    end
  end
end
