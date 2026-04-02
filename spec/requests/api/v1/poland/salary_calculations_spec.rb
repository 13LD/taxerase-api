require "rails_helper"

RSpec.describe "Api::V1::Poland::SalaryCalculations", type: :request do
  describe "POST /api/v1/poland/salary_calculation" do
    it "returns an employee salary breakdown" do
      post api_v1_poland_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 120_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_poland",
            age_bracket: "age_26_to_retirement",
            children_count: 2
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "country_code")).to eq("PL")
      expect(json.dig("metadata", "tax_regime_key")).to eq("employee_poland")
      expect(json.dig("metadata", "tax_regime_name")).to eq("Contract of employment - Poland")
      expect(json.dig("breakdown", "annual_net_income")).to be > 0
      expect(json["sources"]).not_to be_empty
    end

    it "applies Poland's special PIT exemption family to employee income" do
      post api_v1_poland_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 120_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_poland",
            age_bracket: "age_26_to_retirement",
            children_count: 0
          }
        },
        as: :json

      baseline = JSON.parse(response.body)

      post api_v1_poland_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 120_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_poland",
            age_bracket: "age_26_to_retirement",
            children_count: 0,
            apply_return_relief: true
          }
        },
        as: :json

      json = JSON.parse(response.body)

      expect(json.dig("breakdown", "special_relief_exempt_income")).to eq(85_528.0)
      expect(json.dig("breakdown", "annual_income_tax")).to be <= baseline.dig("breakdown", "annual_income_tax")
      expect(json.dig("input", "apply_return_relief")).to be(true)
      expect(json["detail_cards"]).to include(include("label" => "Special PIT exemption income"))
    end

    it "accepts EUR input for Poland and converts it to PLN before calculation" do
      converter = Taxerase::Comparisons::EcbReferenceRateConverter.new
      converted_income = converter.convert(10_000, from_currency_code: "EUR", to_currency_code: "PLN")
      expected_result = Taxerase::Poland::CalculationRouter.call(
        gross_income: converted_income,
        input_currency_code: "PLN",
        tax_year: 2025,
        salary_period: "YEAR",
        tax_regime_key: "employee_poland",
        age_bracket: "age_26_to_retirement",
        children_count: 0
      )

      post api_v1_poland_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 10_000,
            input_currency_code: "EUR",
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_poland",
            age_bracket: "age_26_to_retirement",
            children_count: 0
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("input", "input_currency_code")).to eq("EUR")
      expect(json.dig("metadata", "input_currency_code")).to eq("EUR")
      expect(json.dig("metadata", "display_currency_code")).to eq("EUR")
      expect(json["assumptions"].first).to include("converted to PLN")
      expect(json["assumptions"][1]).to include("converted back to EUR")
      expect(json.dig("input", "gross_income")).to eq(10_000.0)
      expect(json.dig("breakdown", "annual_net_income")).to eq(
        converter.convert_to_eur(expected_result.dig(:breakdown, :annual_net_income), "PLN")
      )
    end

    it "returns a self-employed breakdown" do
      post api_v1_poland_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 180_000,
            deductible_expenses: 35_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_poland",
            age_bracket: "age_26_to_retirement",
            children_count: 1
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "tax_regime_key")).to eq("self_employed_poland")
      expect(json.dig("metadata", "tax_regime_name")).to eq("B2B contract - Poland")
      expect(json.dig("breakdown", "annual_deductible_expenses")).to eq(35_000.0)
      expect(json.dig("breakdown", "annual_social_security")).to be > 0
      expect(json.dig("breakdown", "annual_health_contribution")).to be > 0
      expect(json.dig("breakdown", "annual_invoice_total_with_vat")).to be_nil
      expect(json.dig("input", "vat_rate")).to be_nil
    end

    it "returns validation errors for invalid input" do
      post api_v1_poland_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 0,
            deductible_expenses: -1,
            tax_year: 2025,
            salary_period: "DAY",
            tax_regime_key: "self_employed_poland",
            age_bracket: "unknown",
            children_count: -1
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include("gross_income must be a number greater than 0")
      expect(json["errors"]).to include("deductible_expenses must be 0 or greater")
      expect(json["errors"]).to include("salary_period must be YEAR or MONTH")
      expect(json["errors"]).to include("age_bracket must be one of: under_26, age_26_to_retirement, retirement_age_or_older")
    end

    it "validates the family 4+ and working senior relief eligibility rules" do
      post api_v1_poland_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 120_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_poland",
            age_bracket: "age_26_to_retirement",
            children_count: 2,
            apply_family_4plus_relief: true,
            apply_working_senior_relief: true
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include("family 4+ relief requires at least 4 children")
      expect(json["errors"]).to include("working senior relief requires retirement age or older")
    end
  end
end
