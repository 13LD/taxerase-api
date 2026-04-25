Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home"

  namespace :api do
    namespace :v1 do
      get "countries/:country_code/calculator", to: "country_calculators#show", as: :country_calculator
      get "countries/:country_code/report_calendar", to: "report_calendars#show", as: :country_report_calendar

      resources :comparisons, only: :create

      namespace :spain do
        resource :salary_calculation, only: :create
      end

      namespace :andorra do
        resource :salary_calculation, only: :create
      end

      namespace :netherlands do
        resource :salary_calculation, only: :create
      end

      namespace :poland do
        resource :salary_calculation, only: :create
      end

      namespace :czech_republic do
        resource :salary_calculation, only: :create
      end

      namespace :portugal do
        resource :salary_calculation, only: :create
      end
    end
  end
end
