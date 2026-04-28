Rails.application.routes.draw do
  devise_for :users,
             path: "",
             path_names: {
               sign_in: "sign_in",
               sign_out: "sign_out",
               sign_up: "sign_up",
               password: "password",
               confirmation: "confirmation"
             },
             controllers: {
               sessions: "users/sessions",
               registrations: "users/registrations",
               confirmations: "users/confirmations"
             }

  resource :profile, only: [ :edit, :update ], controller: "users/profiles"

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

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
