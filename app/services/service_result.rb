class ServiceResult
  def initialize success:, data: nil, errors: []
    unless success.in? [true, false]
      raise ArgumentError, "success must be true or false"
    end

    @success = success
    @data = data
    @errors = errors
  end

  attr_reader :success, :data, :errors

  def success?
    success
  end

  def failure?
    !success
  end

  def has_data?
    data.present?
  end

  def has_errors?
    errors.present?
  end

  def error_message
    errors.map(&:to_s)
  end
end