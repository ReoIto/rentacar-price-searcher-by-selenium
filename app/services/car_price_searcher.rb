class CarPriceSearcher
  include BaseService
  require 'selenium-webdriver'
  require 'webdrivers'

  def initialize start_year, start_month, start_day, start_time,
    return_year, return_month, return_day, return_time

    @start_year = start_year
    @start_month = start_month
    @start_day = start_day
    @start_time = start_time

    @return_year = return_year
    @return_month = return_month
    @return_day = return_day
    @return_time = return_time

    @selenium_options = set_selenium_options
  end

  def call
    session = Selenium::WebDriver.for :chrome, options: selenium_options
    # 10秒待っても読み込まれない場合は例外起こす
    session.manage.timeouts.implicit_wait = 10

    url = get_url
    session.navigate.to(url)
    car_lists = session.find_elements(:class, 'plan_contents_list')

    search_results = []
    car_lists.each do |car_info|
      contents = pluck_contents(car_info)

      search_results << contents
    end

    if search_results.present?
      puts search_results
    else
      puts 'no results...'
    end

    sleep(2)
    session.quit # ブラウザ終了
  rescue => e
    session.quit
    puts e
  end

  private
  attr_reader :selenium_options, :start_year, :start_month, :start_day,
    :start_time, :return_year, :return_month, :return_day, :return_time

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
    "https://skyticket.jp/rentacar/okinawa/naha_airport/" \
      "?time=#{start_time}" \
      "&prefecture=47" \
      "&area_id=271" \
      "&airport_id=326" \
      "&station_id=9200" \
      "&return_time=#{return_time}" \
      "&return_prefecture=0" \
      "&return_airport_id=0" \
      "&checkbox=1" \
      "&place=3" \
      "&return_way=" \
      "0&year=#{start_year}" \
      "&month=#{start_month}" \
      "&day=#{start_day}" \
      "&return_year=#{return_year}" \
      "&return_month=#{return_month}" \
      "&return_day=#{return_day}" \
      "&area_type=0"
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
end