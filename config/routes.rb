Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home"

  namespace :api do
    namespace :v1 do
      resources :comparisons, only: :create

      namespace :spain do
        resource :salary_calculation, only: :create
      end

      namespace :netherlands do
        resource :salary_calculation, only: :create
      end
    end
  end
end
