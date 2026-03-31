require "rails_helper"

RSpec.describe "Api::V1::Spain::SalaryCalculations", type: :request do
  describe "POST /api/v1/spain/salary_calculation" do
    it "returns an employee salary breakdown" do
      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            salary_period: "YEAR",
            tax_regime_key: "employee_madrid"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "country_code")).to eq("ES")
      expect(json.dig("metadata", "tax_regime_key")).to eq("employee_madrid")
      expect(json.dig("breakdown", "annual_net_income")).to be_within(0.01).of(42_236.36)
    end

    it "returns a self-employed breakdown" do
      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            deductible_expenses: 10_000,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_madrid"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "tax_regime_key")).to eq("self_employed_madrid")
      expect(json.dig("breakdown", "annual_deductible_expenses")).to eq(10_000.0)
      expect(json.dig("breakdown", "annual_net_income")).to be_within(0.01).of(34_405.84)
    end

    it "returns validation errors for invalid input" do
      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 0,
            salary_period: "DAY"
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include("gross_income must be a number greater than 0")
      expect(json["errors"]).to include("salary_period must be YEAR or MONTH")
    end

    it "returns a clear error for unsupported regimes" do
      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            salary_period: "YEAR",
            tax_regime_key: "corporate_income_general"
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include(
        "Corporate income tax - general is stored in the rules database, but its calculator flow is not implemented yet."
      )
    end
  end
end
