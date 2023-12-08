class CarPriceSearcher < ::Base
  include PriceCalculatable
  require 'selenium-webdriver'
  require 'webdrivers'

  # @params [String] start_date
  # @params [String] start_time
  # @params [String] return_date
  # @params [String] return_time
  # @return [::ServiceResult]
  def self.execute(start_date, start_time, return_date, return_time)
    new(start_date, start_time, return_date, return_time).search
  end

  private_class_method :new
  attr_reader :selenium_options, :start_date, :start_time, :return_date, :return_time

  def initialize(start_date, start_time, return_date, return_time)
    @start_date = start_date
    @start_time = start_time
    @return_date = return_date
    @return_time = return_time
    @selenium_options = set_selenium_options
  end

  def search
    session = Selenium::WebDriver.for :chrome, options: selenium_options
    # 10秒待っても読み込まれない場合は例外起こす
    session.manage.timeouts.implicit_wait = 10

    url = get_url
    session.navigate.to(url)
    sleep(3)
    car_lists = session.find_elements(:class, 'plan_info_block')
    search_results = []
    car_lists.each do |car_info|
      contents = pluck_contents(car_info)

      search_results << contents
    end

    if search_results.empty?
      data = {
        is_no_result: true
      }
    else
      # formatted_prices be like ["¥30,000(税込)","¥50,600(税込)"]
      formatted_prices = search_results.map{|res| res[:price]}
      prices = remove_format(formatted_prices)

      average_price = average_price(prices)
      cheapest_price = cheapest_price(prices)
      highest_price = highest_price(prices)
      average_price_between_average_and_cheapest =
        average_price([average_price, cheapest_price])

      data = {
        car_list: search_results,
        average_price: average_price,
        cheapest_price: cheapest_price,
        highest_price: highest_price,
        average_price_between_average_and_cheapest:
          average_price_between_average_and_cheapest,
        is_error: false
      }
    end

    ServiceResult.new success: true, data: data
  rescue => e
    output_error(
      e,
      info: "Called CarPriceSearcher.call with\n" \
            "- start_date: #{start_date}, - start_time: #{start_time} " \
            "- return_date: #{return_date}, - return_time: #{return_time}\n" \
            "- selenium_options: #{selenium_options.options}"
    )
    ServiceResult.new success: false, errors: e
  ensure
    session.quit if session
  end

  private

  def set_selenium_options
    # Webdrivers::Chromedriver.required_version = '106.0.5249.21' if Rails.env.development?
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
    # ?time=9-00だとエラーになるため、?time=09-00になるように加工する
    start_hour = start_datetime.hour.to_s.length == 1 ? "0#{start_datetime.hour}" : start_datetime.hour
    return_hour = return_datetime.hour.to_s.length == 1 ? "0#{return_datetime.hour}" : return_datetime.hour
    start_min = start_datetime.min.zero? ? '00' : start_datetime.min
    return_min = return_datetime.min.zero? ? '00' : return_datetime.min

    "https://skyticket.jp/rentacar/okinawa/naha_airport/" \
      "?time=#{start_hour}-#{start_min}" \
      "&prefecture=47" \
      "&area_id=271" \
      "&airport_id=326" \
      "&station_id=9200" \
      "&return_time=#{return_hour}-#{return_min}" \
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
    shop_name = car_info.find_element(:class, 'plan_info_block_shop_name').text
    car_name = car_info.find_element(:class, 'plan_contents_name_wrap').text
    limit_of_passengers = car_info.find_elements(:class, 'plan_car_spec')[1].text
    price_title = car_info.find_element(:class, 'plan_contents_price_title').text
    price = car_info.find_element(:class, 'plan_contents_price').text

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
    formatted_prices.map do |formatted_price|
      formatted_price.delete("^0-9").to_i
    end
  end
end
