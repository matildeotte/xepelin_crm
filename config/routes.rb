Rails.application.routes.draw do
  root "dashboard#index"

  get "login" => "sessions#new"
  get "auth/google_oauth2/callback" => "sessions#create"
  get "auth/failure" => "sessions#failure"
  delete "logout" => "sessions#destroy"

  resources :companies, only: %i[index show update] do
    resources :interactions, only: [:create]
  end

  resources :debtors, only: [:show]

  get "invoices/unpaid" => "invoices#unpaid"
end
