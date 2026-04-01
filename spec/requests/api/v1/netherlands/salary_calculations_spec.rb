require "rails_helper"

RSpec.describe "Api::V1::Netherlands::SalaryCalculations", type: :request do
  describe "POST /api/v1/netherlands/salary_calculation" do
    it "returns an employee salary breakdown" do
      post api_v1_netherlands_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_netherlands",
            age_bracket: "under_aow_age"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "country_code")).to eq("NL")
      expect(json.dig("metadata", "tax_regime_key")).to eq("employee_netherlands")
      expect(json.dig("metadata", "tax_year")).to eq(2025)
      expect(json.dig("breakdown", "annual_net_income")).to be > 0
      expect(json["sources"]).not_to be_empty
    end

    it "applies the AOW age profile to lower the employee tax burden" do
      post api_v1_netherlands_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_netherlands",
            age_bracket: "under_aow_age"
          }
        },
        as: :json

      baseline = JSON.parse(response.body)

      post api_v1_netherlands_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_netherlands",
            age_bracket: "aow_age_or_older"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("input", "age_bracket")).to eq("aow_age_or_older")
      expect(json.dig("breakdown", "annual_income_tax")).to be < baseline.dig("breakdown", "annual_income_tax")
      expect(json.dig("breakdown", "annual_net_income")).to be > baseline.dig("breakdown", "annual_net_income")
    end

    it "applies the 30% ruling to eligible employee income" do
      post api_v1_netherlands_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_netherlands",
            age_bracket: "under_aow_age"
          }
        },
        as: :json

      baseline = JSON.parse(response.body)

      post api_v1_netherlands_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_netherlands",
            age_bracket: "under_aow_age",
            apply_thirty_percent_ruling: true,
            thirty_percent_ruling_basis: "standard_threshold"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("input", "apply_thirty_percent_ruling")).to be(true)
      expect(json.dig("input", "thirty_percent_ruling_basis")).to eq("standard_threshold")
      expect(json.dig("breakdown", "thirty_percent_ruling_untaxed_allowance")).to eq(13_340.0)
      expect(json.dig("breakdown", "taxable_employment_income")).to eq(46_660.0)
      expect(json.dig("breakdown", "annual_income_tax")).to be < baseline.dig("breakdown", "annual_income_tax")
      expect(json.dig("breakdown", "annual_net_income")).to be > baseline.dig("breakdown", "annual_net_income")
      expect(json.dig("detail_cards", 0, "label")).to eq("30% ruling untaxed allowance")
    end

    it "supports the scientific research basis without a salary threshold" do
      post api_v1_netherlands_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 20_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_netherlands",
            age_bracket: "under_aow_age",
            apply_thirty_percent_ruling: true,
            thirty_percent_ruling_basis: "scientific_research"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("breakdown", "thirty_percent_ruling_untaxed_allowance")).to eq(6_000.0)
      expect(json.dig("breakdown", "taxable_employment_income")).to eq(14_000.0)
    end

    it "returns a self-employed breakdown" do
      post api_v1_netherlands_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            deductible_expenses: 10_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_netherlands",
            age_bracket: "under_aow_age"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "tax_regime_key")).to eq("self_employed_netherlands")
      expect(json.dig("metadata", "tax_year")).to eq(2025)
      expect(json.dig("breakdown", "annual_deductible_expenses")).to eq(10_000.0)
      expect(json.dig("breakdown", "zvw_contribution")).to be > 0
      expect(json.dig("breakdown", "annual_net_income")).to be > 0
    end

    it "returns a 2024 employee salary breakdown" do
      post api_v1_netherlands_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2024,
            salary_period: "YEAR",
            tax_regime_key: "employee_netherlands",
            age_bracket: "under_aow_age"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "tax_year")).to eq(2024)
      expect(json["sources"]).not_to be_empty
    end

    it "returns validation errors for invalid input" do
      post api_v1_netherlands_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 0,
            deductible_expenses: -1,
            tax_year: 2025,
            salary_period: "DAY",
            tax_regime_key: "self_employed_netherlands",
            age_bracket: "unknown"
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include("gross_income must be a number greater than 0")
      expect(json["errors"]).to include("deductible_expenses must be 0 or greater")
      expect(json["errors"]).to include("salary_period must be YEAR or MONTH")
      expect(json["errors"]).to include("age_bracket is not supported for the Netherlands calculator")
    end

    it "returns a validation error for an unsupported 30% ruling basis" do
      post api_v1_netherlands_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_netherlands",
            age_bracket: "under_aow_age",
            apply_thirty_percent_ruling: true,
            thirty_percent_ruling_basis: "unknown"
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include(
        "thirty_percent_ruling_basis is not supported for the Netherlands 30% ruling"
      )
    end
  end
end
