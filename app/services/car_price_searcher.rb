class CarPriceSearcher
  include BaseService
  require 'selenium-webdriver'
  require 'webdrivers'

  def initialize search_params
    @start_date = search_params[:start_date]
    @start_time = search_params[:start_time]
    @return_date = search_params[:return_date]
    @return_time = search_params[:return_time]

    @selenium_options = set_selenium_options
  end

  def call
    session = Selenium::WebDriver.for :chrome, options: selenium_options
    # 10秒待っても読み込まれない場合は例外起こす
    session.manage.timeouts.implicit_wait = 10

    url = get_url
    session.navigate.to(url)
    sleep(3)
    car_lists = session.find_elements(:class, 'plan_contents_list')

    search_results = []
    car_lists.each do |car_info|
      contents = pluck_contents(car_info)

      search_results << contents
    end

    unless search_results.present?
      raise StandardError, "no results ... #{url}"
    end

    # formatted_prices be like ["¥30,000(税込)","¥50,600(税込)"]
    formatted_prices = search_results.map{|res| res[:price]}
    prices = remove_format(formatted_prices)

    average_price = calc_average_price(prices)
    cheapest_price = get_cheapest_price(prices)
    highest_price = get_highest_price(prices)

    data = {
      car_list: search_results,
      average_price: average_price,
      cheapest_price: cheapest_price,
      highest_price: highest_price
    }

    session.quit
    ServiceResult.new success: true, data: data
  rescue => e
    session.quit
    puts e
    ServiceResult.new success: false, errors: e
  end

  private
  attr_reader :selenium_options, :start_date, :start_time, :return_date, :return_time

  def set_selenium_options
    options = Selenium::WebDriver::Chrome::Options.new
    options.binary = ENV.fetch("GOOGLE_CHROME_SHIM") if Rails.env.production?
    # コマンドラインからchromeを開く。GUIよりこっちの方が軽い
    options.add_argument('--headless')
    # 「暫定的なフラグ」らしい
    options.add_argument('--disable-gpu')
    # セキュリティ対策などのchromeに搭載してある保護機能をオフにする
    options.add_argument('--no-sandbox')
    # ディスクのメモリスペースを使う
    options.add_argument('--disable-dev-shm-usage')
    # リモートデバッグフラグを立てる
    options.add_argument('--remote-debugging-port=9222')

    options
  end

  def get_url
    start_datetime = Time.parse("#{start_date} #{start_time}")
    return_datetime = Time.parse("#{return_date} #{return_time}")
    "https://skyticket.jp/rentacar/okinawa/naha_airport/" \
      "?time=#{start_datetime.hour}-#{start_datetime.min.zero? ? '00' : start_datetime.min}" \
      "&prefecture=47" \
      "&area_id=271" \
      "&airport_id=326" \
      "&station_id=9200" \
      "&return_time=#{return_datetime.hour}-#{return_datetime.min.zero? ? '00' : return_datetime.min}" \
      "&return_prefecture=0" \
      "&return_airport_id=0" \
      "&checkbox=1" \
      "&place=3" \
      "&return_way=0" \
      "&year=#{start_datetime.year}" \
      "&month=#{start_datetime.month}" \
      "&day=#{start_datetime.day}" \
      "&return_year=#{return_datetime.year}" \
      "&return_month=#{return_datetime.month}" \
      "&return_day=#{return_datetime.day}" \
      "&area_type=0" \
      "&car_type[0]=9" \
      "&car_type[1]=5"
  end

  def pluck_contents car_info
    shop_name =
      car_info
        .find_element(:class, 'plan_contents_list_head')
        .find_element(:class, 'plan_contents_list_head_top')
        .find_element(:class, 'plan_contents_list_shop_name')
        .text

    car_name =
      car_info
        .find_element(:class, 'plan_contents_list_body')
        .find_element(:class, 'plan_contents_name')
        .text

    limit_of_passengers =
      car_info
        .find_element(:class, 'plan_contents_list_body')
        .find_elements(:class, 'plan_car_spec')[1]
        .text

    price_title =
      car_info
        .find_element(:class, 'plan_contents_list_body')
        .find_element(:class, 'plan_contents_list_right')
        .find_element(:class, 'plan_contents_price_title')
        .text

    price =
      car_info
        .find_element(:class, 'plan_contents_list_body')
        .find_element(:class, 'plan_contents_list_right')
        .find_element(:class, 'plan_contents_price')
        .text

    {
      shop_name: shop_name,
      car_name: car_name,
      limit_of_passengers: limit_of_passengers,
      price_title: price_title,
      price: price
    }
  end

  def remove_format formatted_prices
    # ["¥30,000(税込)","¥50,600(税込)"]
    # ↓ to be
    # [30000, 50600]
    unformatted_prices = []
    formatted_prices.each do |formatted_price|
      unformatted_prices << formatted_price.delete("^0-9").to_i
    end

    unformatted_prices
  end

  def calc_average_price prices
    prices.sum / prices.length
  end

  def get_cheapest_price prices
    prices.min
  end

  def get_highest_price price
    price.max
  end
end