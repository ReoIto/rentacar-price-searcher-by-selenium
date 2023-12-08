class SearchPricesController < ApplicationController
  def search
    result = CarPriceSearcher.execute(search_params[:start_date], search_params[:start_time], search_params[:return_date], search_params[:return_time])

    if result.success?
      render json: { search_result: result.data }, status: :ok
    else
      render json: { search_result: { is_error: true }}, status: :internal_server_error
    end
  end

  private

    def search_params
      return @search_params if defined? @search_params

      @search_params = params.permit(:start_date, :start_time, :return_date, :return_time)
    end
end
