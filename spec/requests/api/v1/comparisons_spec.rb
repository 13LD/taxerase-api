require "rails_helper"

RSpec.describe "Api::V1::Comparisons", type: :request do
  describe "POST /api/v1/comparisons" do
    it "compares Spain and the Netherlands for an employee profile" do
      post api_v1_comparisons_path,
        params: {
          comparison: {
            left_country_code: "ES",
            left_tax_regime_key: "employee_madrid",
            right_country_code: "NL",
            right_tax_regime_key: "employee_netherlands",
            tax_year: 2025,
            selected_category: "employee",
            gross_income: 60_000,
            salary_period: "YEAR"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("left", "country_code")).to eq("ES")
      expect(json.dig("right", "country_code")).to eq("NL")
      expect(json.dig("metadata", "comparison_currency_code")).to eq("EUR")
      expect(json.dig("metadata", "mixed_currency_comparison")).to eq(false)
      expect(json["summary_metrics"].map { |metric| metric["key"] }).to eq(
        %w[annual_net_income monthly_net_income effective_tax_rate total_tax]
      )
    end

    it "compares Spain and Andorra for an employee profile" do
      post api_v1_comparisons_path,
        params: {
          comparison: {
            left_country_code: "ES",
            left_tax_regime_key: "employee_madrid",
            right_country_code: "AD",
            right_tax_regime_key: "employee_andorra",
            tax_year: 2025,
            selected_category: "employee",
            gross_income: 60_000,
            salary_period: "YEAR"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("right", "country_code")).to eq("AD")
      expect(json.dig("metadata", "comparison_currency_code")).to eq("EUR")
      expect(json["summary_metrics"].map { |metric| metric["key"] }).to include("annual_net_income", "total_tax")
    end

    it "compares two Spain regions under the same employee profile" do
      post api_v1_comparisons_path,
        params: {
          comparison: {
            left_country_code: "ES",
            left_tax_regime_key: "employee_andalusia",
            right_country_code: "ES",
            right_tax_regime_key: "employee_madrid",
            tax_year: 2025,
            selected_category: "employee",
            gross_income: 60_000,
            salary_period: "YEAR"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("left", "region")).to eq("Andalusia")
      expect(json.dig("right", "region")).to eq("Madrid")
      expect(json["summary_metrics"]).not_to be_empty
    end

    it "compares Spain and the Netherlands for a self-employed profile" do
      post api_v1_comparisons_path,
        params: {
          comparison: {
            left_country_code: "ES",
            left_tax_regime_key: "self_employed_madrid",
            right_country_code: "NL",
            right_tax_regime_key: "self_employed_netherlands",
            tax_year: 2025,
            selected_category: "self_employed",
            gross_income: 60_000,
            deductible_expenses: 12_000,
            salary_period: "YEAR"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      total_tax_metric = json["summary_metrics"].find { |metric| metric["key"] == "total_tax" }

      expect(total_tax_metric["left_value"]).to be > 0
      expect(total_tax_metric["right_value"]).to be > 0
    end

    it "does not rebuild global comparison catalog data for every country" do
      query_count = count_application_queries do
        post api_v1_comparisons_path,
          params: {
            comparison: {
              left_country_code: "ES",
              left_tax_regime_key: "self_employed_madrid",
              right_country_code: "NL",
              right_tax_regime_key: "self_employed_netherlands",
              tax_year: 2025,
              selected_category: "self_employed",
              gross_income: 60_000,
              deductible_expenses: 0,
              salary_period: "YEAR"
            }
          },
          as: :json
      end

      expect(response).to have_http_status(:ok)
      expect(query_count).to be < 30
    end

    it "uses Poland flat tax for self-employed comparisons" do
      flat_tax_result = Taxerase::Poland::CalculationRouter.call(
        gross_income: 120_000,
        salary_period: "YEAR",
        tax_year: 2025,
        tax_regime_key: "self_employed_poland",
        deductible_expenses: 20_000,
        b2b_tax_form: "flat_tax"
      )
      tax_scale_result = Taxerase::Poland::CalculationRouter.call(
        gross_income: 120_000,
        salary_period: "YEAR",
        tax_year: 2025,
        tax_regime_key: "self_employed_poland",
        deductible_expenses: 20_000,
        b2b_tax_form: "tax_scale"
      )

      post api_v1_comparisons_path,
        params: {
          comparison: {
            left_country_code: "PL",
            left_tax_regime_key: "self_employed_poland",
            right_country_code: "PL",
            right_tax_regime_key: "self_employed_poland",
            tax_year: 2025,
            selected_category: "self_employed",
            gross_income: 120_000,
            deductible_expenses: 20_000,
            salary_period: "YEAR"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      annual_net_income_metric = json["summary_metrics"].find { |metric| metric["key"] == "annual_net_income" }
      total_tax_metric = json["summary_metrics"].find { |metric| metric["key"] == "total_tax" }

      expect(annual_net_income_metric["right_value"]).to be_within(0.01).of(
        flat_tax_result.dig(:breakdown, :annual_net_income)
      )
      expect(total_tax_metric["right_value"]).to be_within(0.01).of(
        flat_tax_result.dig(:breakdown, :total_tax)
      )
      expect(annual_net_income_metric["right_value"]).not_to be_within(0.01).of(
        tax_scale_result.dig(:breakdown, :annual_net_income)
      )
    end

    it "normalizes mixed-currency comparisons to EUR for Poland" do
      post api_v1_comparisons_path,
        params: {
          comparison: {
            left_country_code: "ES",
            left_tax_regime_key: "employee_madrid",
            right_country_code: "PL",
            right_tax_regime_key: "employee_poland",
            tax_year: 2025,
            selected_category: "employee",
            gross_income: 60_000,
            salary_period: "YEAR"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      annual_net_income_metric = json["summary_metrics"].find { |metric| metric["key"] == "annual_net_income" }

      expect(json.dig("metadata", "input_currency_code")).to eq("EUR")
      expect(json.dig("metadata", "comparison_currency_code")).to eq("EUR")
      expect(json.dig("metadata", "mixed_currency_comparison")).to eq(true)
      expect(json.dig("metadata", "fx_reference", "provider")).to eq("Frankfurter")
      expect(json.dig("metadata", "fx_reference", "rate_date")).to eq("2026-03-11")
      expect(json.dig("right", "currency_code")).to eq("PLN")
      expect(json.dig("right", "gross_income_input")).to be > 60_000
      expect(annual_net_income_metric["display_currency_code"]).to eq("EUR")
      expect(annual_net_income_metric["converted_from_local"]).to eq(true)
      expect(annual_net_income_metric["right_local_currency_code"]).to eq("PLN")
      expect(annual_net_income_metric["right_local_value"]).to be > annual_net_income_metric["right_value"]
    end

    it "accepts Czech koruna as the shared comparison input currency for Spain and Czech Republic" do
      converter = Taxerase::Comparisons::EcbReferenceRateConverter.new
      czech_result = Taxerase::CzechRepublic::CalculationRouter.call(
        gross_income: 600_000,
        salary_period: "YEAR",
        tax_year: 2025,
        tax_regime_key: "self_employed_czech_republic",
        deductible_expenses: 0,
        expense_deduction_method: "flat_expense_60",
        children_count: 0,
        disability_level: "none",
        input_currency_code: "CZK"
      )

      post api_v1_comparisons_path,
        params: {
          comparison: {
            left_country_code: "ES",
            left_tax_regime_key: "self_employed_andalusia",
            right_country_code: "CZ",
            right_tax_regime_key: "self_employed_czech_republic",
            tax_year: 2025,
            selected_category: "self_employed",
            gross_income: 600_000,
            input_currency_code: "CZK",
            deductible_expenses: 0,
            salary_period: "YEAR"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      annual_net_income_metric = json["summary_metrics"].find { |metric| metric["key"] == "annual_net_income" }
      effective_tax_rate_metric = json["summary_metrics"].find { |metric| metric["key"] == "effective_tax_rate" }
      total_tax_metric = json["summary_metrics"].find { |metric| metric["key"] == "total_tax" }

      expect(json.dig("metadata", "input_currency_code")).to eq("CZK")
      expect(json.dig("metadata", "comparison_currency_code")).to eq("EUR")
      expect(json.dig("right", "gross_income_input")).to eq(600_000.0)
      expect(annual_net_income_metric["right_local_currency_code"]).to eq("CZK")
      expect(annual_net_income_metric["right_local_value"]).to be_within(0.01).of(
        czech_result.dig(:breakdown, :annual_net_income)
      )
      expect(effective_tax_rate_metric["right_value"]).to be_within(0.01).of(
        czech_result.dig(:breakdown, :effective_tax_rate)
      )
      expect(total_tax_metric["right_local_value"]).to be_within(0.01).of(
        czech_result.dig(:breakdown, :total_tax)
      )
      expect(total_tax_metric["right_value"]).to be_within(0.01).of(
        converter.convert_to_eur(czech_result.dig(:breakdown, :total_tax), "CZK")
      )
    end

    it "uses the Czech 60% flat expense method by default for self-employed comparisons" do
      flat_expense_result = Taxerase::CzechRepublic::CalculationRouter.call(
        gross_income: 900_000,
        salary_period: "YEAR",
        tax_year: 2025,
        tax_regime_key: "self_employed_czech_republic",
        deductible_expenses: 250_000,
        expense_deduction_method: "flat_expense_60",
        children_count: 0,
        disability_level: "none"
      )
      actual_expenses_result = Taxerase::CzechRepublic::CalculationRouter.call(
        gross_income: 900_000,
        salary_period: "YEAR",
        tax_year: 2025,
        tax_regime_key: "self_employed_czech_republic",
        deductible_expenses: 250_000,
        expense_deduction_method: "actual_expenses",
        children_count: 0,
        disability_level: "none"
      )

      post api_v1_comparisons_path,
        params: {
          comparison: {
            left_country_code: "CZ",
            left_tax_regime_key: "self_employed_czech_republic",
            right_country_code: "CZ",
            right_tax_regime_key: "self_employed_czech_republic",
            tax_year: 2025,
            selected_category: "self_employed",
            gross_income: 900_000,
            deductible_expenses: 250_000,
            salary_period: "YEAR"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      annual_net_income_metric = json["summary_metrics"].find { |metric| metric["key"] == "annual_net_income" }
      total_tax_metric = json["summary_metrics"].find { |metric| metric["key"] == "total_tax" }

      expect(annual_net_income_metric["right_value"]).to be_within(0.01).of(
        flat_expense_result.dig(:breakdown, :annual_net_income)
      )
      expect(total_tax_metric["right_value"]).to be_within(0.01).of(
        flat_expense_result.dig(:breakdown, :total_tax)
      )
      expect(annual_net_income_metric["right_value"]).not_to be_within(0.01).of(
        actual_expenses_result.dig(:breakdown, :annual_net_income)
      )
    end

    it "accepts high mixed-currency self-employed comparison inputs without tripping local currency caps" do
      post api_v1_comparisons_path,
        params: {
          comparison: {
            left_country_code: "ES",
            left_tax_regime_key: "self_employed_madrid",
            right_country_code: "CZ",
            right_tax_regime_key: "self_employed_czech_republic",
            tax_year: 2025,
            selected_category: "self_employed",
            gross_income: 450_000,
            deductible_expenses: 0,
            salary_period: "YEAR"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "mixed_currency_comparison")).to eq(true)
      expect(json.dig("right", "gross_income_input")).to be > 10_000_000
      expect(json["summary_metrics"]).not_to be_empty
    end

    it "returns validation errors for mismatched tax profiles" do
      post api_v1_comparisons_path,
        params: {
          comparison: {
            left_country_code: "ES",
            left_tax_regime_key: "employee_madrid",
            right_country_code: "NL",
            right_tax_regime_key: "self_employed_netherlands",
            tax_year: 2025,
            selected_category: "employee",
            gross_income: 60_000,
            salary_period: "YEAR"
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include("right comparison selection does not match the selected tax profile")
    end

    it "returns a validation error for an unregistered comparison profile" do
      post api_v1_comparisons_path,
        params: {
          comparison: {
            left_country_code: "ES",
            left_tax_regime_key: "employee_madrid",
            right_country_code: "NL",
            right_tax_regime_key: "employee_netherlands",
            tax_year: 2025,
            selected_category: "special_regime",
            gross_income: 60_000,
            salary_period: "YEAR"
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include("selected_category is not a registered comparison profile")
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
