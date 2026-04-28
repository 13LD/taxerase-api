require "rails_helper"

RSpec.describe "Pages", type: :request do
  CALCULATION_ROUTERS = [
    Taxerase::Andorra::CalculationRouter,
    Taxerase::Spain::CalculationRouter,
    Taxerase::Netherlands::CalculationRouter,
    Taxerase::Poland::CalculationRouter,
    Taxerase::CzechRepublic::CalculationRouter,
    Taxerase::Portugal::CalculationRouter
  ].freeze

  describe "GET /" do
    it "renders the home page" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Taxerase")
      expect(response.body).to include("country-calculator-app")
      expect(response.body).to include("Andorra")
      expect(response.body).to include("Spain")
      expect(response.body).to include("Netherlands")
      expect(response.body).to include("Poland")
      expect(response.body).to include("Czech Republic")
      expect(response.body).to include("Portugal")
      expect(response.body).to include("employee_andorra")
      expect(response.body).to include("self_employed_andorra")
      expect(response.body).to include("employee_madrid")
      expect(response.body).to include("self_employed_madrid")
      expect(response.body).to include("beckham_madrid")
      expect(response.body).to include("employee_portugal")
      expect(response.body).to include("self_employed_portugal")
      expect(response.body).to include("2024")
      expect(response.body).to include("2025")
      expect(response.body).to include("2026")
      expect(response.body).not_to include("employee_navarre")
    end

    it "builds calculator payload without repeated query-cache work" do
      query_count = count_application_queries do
        get root_path, params: { tab: "calculator" }
      end

      expect(response).to have_http_status(:ok)
      expect(query_count).to be < 30
    end

    it "renders the Spain home page when optional add-on parameter rows are stale" do
      country = Country.find_by!(code: "ES")
      regimes = TaxRegime.for_country_year(country:, tax_year: 2025).where(key: %w[employee_andalusia])
      TaxParameter.where(
        tax_regime: regimes,
        key: %w[
          employee_solidarity_rate
          ascendant_minimum
          ascendant_over_75_increment
          ascendant_disability_33_minimum
          ascendant_disability_65_minimum
          ascendant_disability_support_increment
          professional_fee_deduction_cap
          legal_defense_deduction_cap
          maternity_monthly_deduction
          nursery_deduction_cap
          large_family_general_deduction
          large_family_special_deduction
          large_family_extra_child_deduction
          family_disability_deduction
          spouse_disability_deduction
        ]
      ).delete_all

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Taxerase | Spain Tax Calculator")
      expect(response.body).to include("employee_andalusia")
    end

    it "renders the Andorra calculator page when requested" do
      get root_path, params: { country: "AD" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Taxerase | Andorra Tax Calculator")
      expect(response.body).to include("employee_andorra")
      expect(response.body).to include("self_employed_andorra")
      expect(response.body).to include("&quot;code&quot;:&quot;AD&quot;")
    end

    it "renders the Netherlands calculator page when requested" do
      get root_path, params: { country: "NL" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Taxerase | Netherlands Tax Calculator")
      expect(response.body).to include("employee_netherlands")
      expect(response.body).to include("self_employed_netherlands")
      expect(response.body).to include("&quot;code&quot;:&quot;NL&quot;")
    end

    it "renders the Poland calculator page when requested" do
      get root_path, params: { country: "PL" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Taxerase | Poland Tax Calculator")
      expect(response.body).to include("employee_poland")
      expect(response.body).to include("&quot;code&quot;:&quot;PL&quot;")
      expect(response.body).to include("&quot;currency_code&quot;:&quot;PLN&quot;")
    end

    it "renders the Czech Republic calculator page when requested" do
      get root_path, params: { country: "CZ" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Taxerase | Czech Republic Tax Calculator")
      expect(response.body).to include("employee_czech_republic")
      expect(response.body).to include("&quot;code&quot;:&quot;CZ&quot;")
      expect(response.body).to include("&quot;currency_code&quot;:&quot;CZK&quot;")
    end

    it "renders the Portugal calculator page when requested" do
      get root_path, params: { country: "PT" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Taxerase | Portugal Tax Calculator")
      expect(response.body).to include("employee_portugal")
      expect(response.body).to include("self_employed_portugal")
      expect(response.body).to include("&quot;code&quot;:&quot;PT&quot;")
    end

    it "uses the signed-in user's profile country when no country is requested" do
      user = User.create!(
        email: "profile-country@example.com",
        password: "password123",
        confirmed_at: Time.current
      )
      user.create_profile!(country_code: "PT", profile_type: "self_employed")

      post user_session_path, params: {
        user: {
          email: user.email,
          password: "password123"
        }
      }
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Taxerase | Portugal Tax Calculator")
      expect(response.body).to include("&quot;code&quot;:&quot;PT&quot;")
      expect(response.body).to include("&quot;default_tax_regime_key&quot;:&quot;self_employed_portugal&quot;")
      expect(response.body).to include("&quot;profile_type&quot;:&quot;self_employed&quot;")
    end

    it "lets explicit country and profile type params override signed-in profile defaults" do
      user = User.create!(
        email: "profile-override@example.com",
        password: "password123",
        confirmed_at: Time.current
      )
      user.create_profile!(country_code: "PT", profile_type: "self_employed")

      post user_session_path, params: {
        user: {
          email: user.email,
          password: "password123"
        }
      }
      get root_path, params: { country: "NL", profile_type: "employee", tab: "calendar" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Taxerase | Netherlands Tax Calculator")
      expect(response.body).to include("&quot;code&quot;:&quot;NL&quot;")
      expect(response.body).to include("&quot;default_tax_regime_key&quot;:&quot;employee_netherlands&quot;")
    end

    it "ignores unsupported profile type params and uses the signed-in profile default" do
      user = User.create!(
        email: "unsupported-profile-param@example.com",
        password: "password123",
        confirmed_at: Time.current
      )
      user.create_profile!(country_code: "PT", profile_type: "self_employed")

      post user_session_path, params: {
        user: {
          email: user.email,
          password: "password123"
        }
      }
      get root_path, params: { profile_type: "contractor" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Taxerase | Portugal Tax Calculator")
      expect(response.body).to include("&quot;default_tax_regime_key&quot;:&quot;self_employed_portugal&quot;")
      expect(response.body).to include("&quot;profile_type&quot;:&quot;self_employed&quot;")
    end

    it "falls back to the first available seeded calculator when a registered country is missing" do
      reset_country_cache!
      Country.find_by!(code: "PT").destroy!
      reset_country_cache!

      get root_path, params: { country: "PT" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Taxerase | Spain Tax Calculator")
      expect(response.body).not_to include("Portugal")
      expect(response.body).to include("&quot;code&quot;:&quot;ES&quot;")
    end

    it "falls back when the signed-in profile country has no seed row" do
      user = User.create!(
        email: "stale-profile-country@example.com",
        password: "password123",
        confirmed_at: Time.current
      )
      user.create_profile!(country_code: "PT", profile_type: "self_employed")

      post user_session_path, params: {
        user: {
          email: user.email,
          password: "password123"
        }
      }

      reset_country_cache!
      Country.find_by!(code: "PT").destroy!
      reset_country_cache!

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Taxerase | Spain Tax Calculator")
      expect(response.body).to include("&quot;code&quot;:&quot;ES&quot;")
      expect(response.body).to include("&quot;selected_country_name&quot;:null")
    end
  end

  describe "GET /api/v1/countries/:country_code/calculator" do
    it "returns calculator props for a country without rendering the full page" do
      get api_v1_country_calculator_path(country_code: "NL")

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["page_title"]).to eq("Taxerase | Netherlands Tax Calculator")
      expect(json.dig("calculator_props", "country", "code")).to eq("NL")
      expect(json.dig("calculator_props", "regime_options").map { |entry| entry["key"] })
        .to include("employee_netherlands", "self_employed_netherlands")
    end

    it "applies the signed-in user's profile type to calculator props when no profile type is requested" do
      user = User.create!(
        email: "api-profile-type@example.com",
        password: "password123",
        confirmed_at: Time.current
      )
      user.create_profile!(country_code: "PT", profile_type: "self_employed")

      post user_session_path, params: {
        user: {
          email: user.email,
          password: "password123"
        }
      }
      get api_v1_country_calculator_path(country_code: "NL")

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json.dig("calculator_props", "default_tax_regime_key")).to eq("self_employed_netherlands")
      expect(json.dig("calculator_props", "initial_result", "metadata", "tax_regime_key"))
        .to eq("self_employed_netherlands")
    end

    it "ignores unsupported API profile type params and uses the signed-in profile default" do
      user = User.create!(
        email: "api-unsupported-profile-type@example.com",
        password: "password123",
        confirmed_at: Time.current
      )
      user.create_profile!(country_code: "PT", profile_type: "self_employed")

      post user_session_path, params: {
        user: {
          email: user.email,
          password: "password123"
        }
      }
      get api_v1_country_calculator_path(country_code: "NL"), params: { profile_type: "contractor" }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json.dig("calculator_props", "default_tax_regime_key")).to eq("self_employed_netherlands")
      expect(json.dig("calculator_props", "initial_result", "metadata", "tax_regime_key"))
        .to eq("self_employed_netherlands")
    end

    it "returns calculator props when auth profile country has no seed row" do
      user = User.create!(
        email: "api-stale-profile-country@example.com",
        password: "password123",
        confirmed_at: Time.current
      )
      user.create_profile!(country_code: "PT", profile_type: "employee")

      post user_session_path, params: {
        user: {
          email: user.email,
          password: "password123"
        }
      }

      reset_country_cache!
      Country.find_by!(code: "PT").destroy!
      reset_country_cache!

      get api_v1_country_calculator_path(country_code: "NL")

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json.dig("calculator_props", "country", "code")).to eq("NL")
      expect(json.dig("calculator_props", "auth", "selected_country_name")).to be_nil
    end

    it "returns Andorra calculator props" do
      get api_v1_country_calculator_path(country_code: "AD")

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["page_title"]).to eq("Taxerase | Andorra Tax Calculator")
      expect(json.dig("calculator_props", "country", "code")).to eq("AD")
      expect(json.dig("calculator_props", "regime_options").map { |entry| entry["key"] })
        .to include("employee_andorra", "self_employed_andorra")
    end

    it "returns Andorra calculator props when local Andorra seed rows are stale" do
      country = Country.find_by!(code: "AD")
      regime = TaxRegime.for_country_year(country:, tax_year: 2026).find_by!(key: "employee_andorra")
      TaxParameter.where(
        tax_regime: regime,
        key: %w[
          habitual_home_investment_reduction_rate
          habitual_home_investment_reduction_cap
          affordable_rental_housing_investment_reduction_rate
          affordable_rental_housing_investment_reduction_cap
          higher_education_tuition_reduction_cap
        ]
      ).delete_all

      get api_v1_country_calculator_path(country_code: "AD")

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("calculator_props", "country", "code")).to eq("AD")
    end

    it "returns not found for an unknown country code" do
      get api_v1_country_calculator_path(country_code: "IT")

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)["errors"]).to include('No country calculator is registered for "IT".')
    end

    it "returns not found for a registered country without seed data" do
      reset_country_cache!
      Country.find_by!(code: "PT").destroy!
      reset_country_cache!

      get api_v1_country_calculator_path(country_code: "PT")

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)["errors"]).to include("Portugal calculator data is not available. Run db:seed.")
    end
  end

  def reset_country_cache!
    CALCULATION_ROUTERS.each do |router|
      router.remove_instance_variable(:@country) if router.instance_variable_defined?(:@country)
    end
  end

  def count_application_queries
    query_count = 0
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      payload = event.payload
      next if payload[:name] == "SCHEMA" || payload[:cached]

      query_count += 1
    end

    ActiveRecord::Base.connection.clear_query_cache
    yield
    query_count
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end
end
