class SearchPricesController < ApplicationController
  def search
    result = CarPriceSearcher.call 2022, 8, 20, '11-00', 2022, 8, 23, '17-00'
    if result.success?
      render json: {search_result: result.data}, status: :ok
    else
      render json: {search_result: 'Sorry. There is no results.'}, status: :internal_server_error
    end
  end
end