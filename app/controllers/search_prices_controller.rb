class SearchPricesController < ApplicationController
  def search
    # def initialize start_year, start_month, start_day, start_time,
    #   return_year, return_month, return_day, return_time
    result = CarPriceSearcher.call 2022, 8, 20, '11-00', 2022, 8, 23, '17-00'
    if result.success?
      render json: {search_results: result.data}, status: :ok
    else
      render json: {search_results: 'Sorry. There is no results.'}, status: :internal_server_error
    end
  end
end