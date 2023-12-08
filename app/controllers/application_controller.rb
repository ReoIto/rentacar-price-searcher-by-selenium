class ApplicationController < ActionController::API
  before_action :params_to_snake_case!

  private

    def params_to_snake_case!
      params.transform_keys! { |k| k.underscore }
    end
end
