module PriceCalculatable
  extend ActiveSupport::Concern

  # @param Array<Integer> prices
  def average_price(prices)
    prices.sum / prices.length
  end

  # @param Array<Integer> prices
  def cheapest_price(prices)
    prices.min
  end

  # @param Array<Integer> prices
  def highest_price(prices)
    prices.max
  end
end
