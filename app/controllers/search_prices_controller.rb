class SearchPricesController < ApplicationController
  def search
    result = CarPriceSearcher.call search_params

    if result.success?
      render json: {search_result: result.data}, status: :ok
    else
      render json: {
        search_result: {
          is_error: true
        }
      }, status: :internal_server_error
    end
  end

  private

  def search_params
    params.transform_keys!{|k| k.underscore}
      .permit(:start_date, :start_time, :return_date, :return_time)

    search_params = {
      start_date: params[:start_date],
      start_time: params[:start_time],
      return_date: params[:return_date],
      return_time: params[:return_time],
    }
  end
end