require "rails_helper"

RSpec.describe "Api::V1::Andorra::SalaryCalculations", type: :request do
  describe "POST /api/v1/andorra/salary_calculation" do
    it "returns an employee salary breakdown" do
      post api_v1_andorra_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_andorra",
            children_count: 2,
            children_under_three_count: 0,
            disability_level: "recognized_disability",
            ascendants_count: 1
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "country_code")).to eq("AD")
      expect(json.dig("metadata", "tax_regime_key")).to eq("employee_andorra")
      expect(json.dig("breakdown", "annual_social_security")).to eq(3_900.0)
      expect(json.dig("breakdown", "work_expense_deduction")).to eq(1_800.0)
      expect(json.dig("breakdown", "annual_income_tax")).to be > 0
      expect(json.dig("breakdown", "earned_income_bonus")).to eq(800.0)
      expect(json["sources"]).not_to be_empty
    end

    it "reduces Andorra employee tax when family and disability reductions increase" do
      post api_v1_andorra_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_andorra",
            children_count: 0,
            children_under_three_count: 0,
            disability_level: "none",
            ascendants_count: 0
          }
        },
        as: :json

      baseline = JSON.parse(response.body)

      post api_v1_andorra_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_andorra",
            children_count: 2,
            children_under_three_count: 0,
            disability_level: "recognized_disability",
            ascendants_count: 1
          }
        },
        as: :json

      json = JSON.parse(response.body)

      expect(json.dig("breakdown", "annual_income_tax")).to be < baseline.dig("breakdown", "annual_income_tax")
      expect(json.dig("breakdown", "annual_net_income")).to be > baseline.dig("breakdown", "annual_net_income")
    end

    it "returns a self-employed breakdown" do
      post api_v1_andorra_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 70_000,
            deductible_expenses: 10_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_andorra",
            children_count: 1,
            children_under_three_count: 0,
            disability_level: "recognized_disability",
            ascendants_count: 0
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "tax_regime_key")).to eq("self_employed_andorra")
      expect(json.dig("breakdown", "annual_deductible_expenses")).to eq(10_000.0)
      expect(json.dig("breakdown", "annual_social_security")).to be > 0
      expect(json.dig("breakdown", "earned_income_bonus")).to eq(800.0)
      expect(json["sources"]).not_to be_empty
    end

    it "returns validation errors for invalid input" do
      post api_v1_andorra_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 0,
            deductible_expenses: -1,
            tax_year: 2025,
            salary_period: "DAY",
            tax_regime_key: "self_employed_andorra",
            children_count: -1,
            children_under_three_count: 0,
            disability_level: "invalid",
            ascendants_count: -1
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include("gross_income must be a number greater than 0")
      expect(json["errors"]).to include("deductible_expenses must be 0 or greater")
      expect(json["errors"]).to include("salary_period must be YEAR or MONTH")
      expect(json["errors"]).to include("children_count must be 0 or greater")
      expect(json["errors"]).to include("disability_level must be one of: none, recognized_disability")
    end
  end
end
