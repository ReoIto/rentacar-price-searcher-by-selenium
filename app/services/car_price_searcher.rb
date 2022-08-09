class CarPriceSearcher
  require 'selenium-webdriver'

  class << self
    def call
      session = Selenium::WebDriver.for :chrome
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

      puts search_results

      sleep(2)
      session.quit # ブラウザ終了
    end

    private
    def get_url
      "https://skyticket.jp/rentacar/searches" \
        "?time=11-00" \
        "&prefecture=47" \
        "&area_id=271" \
        "&airport_id=326" \
        "&station_id=9200" \
        "&return_time=17-00" \
        "&return_prefecture=0" \
        "&return_airport_id=0" \
        "&place=3" \
        "&return_way=0" \
        "&year=2022" \
        "&month=8" \
        "&day=11" \
        "&return_year=2022" \
        "&return_month=8" \
        "&return_day=12"
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
end