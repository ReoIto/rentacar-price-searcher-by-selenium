module PriceCalculator
  def average_price prices
    prices.sum / prices.length
  end

  def cheapest_price prices
    prices.min
  end

  def highest_price prices
    price.max
  end
end