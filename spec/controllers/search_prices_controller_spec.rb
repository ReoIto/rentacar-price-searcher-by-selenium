require 'json_expressions/rspec'

RSpec.describe 'SearchPricesController', type: :request do
  describe '#index' do
    subject { get(search_prices_path, params: params) }

    context '正常系' do
      let(:params) { { start_date: '2021-01-01', start_time: '10:00', return_date: '2021-01-02', return_time: '10:00' } }
      it '200が返ってくること' do
        subject
        expect(response.status).to eq(200)
      end
    end
  end
end
