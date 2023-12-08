Rails.application.routes.draw do
  resources :search_prices, only: [:index]
end
