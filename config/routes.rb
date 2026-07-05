Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root to: redirect(ENV.fetch("FRONTEND_URL", "http://localhost:3001"))

  get "auth/google_oauth2/callback" => "sessions#create"
  get "auth/failure" => "sessions#failure"
  delete "logout" => "sessions#destroy"

  namespace :api do
    namespace :v1 do
      get "dashboard", to: "dashboard#show"
      resource :session, only: :show

      resources :companies, only: %i[index show] do
        resources :interactions, only: :create
      end

      resources :debtors, only: :show
      get "invoices/unpaid", to: "invoices#unpaid"
    end
  end
end
