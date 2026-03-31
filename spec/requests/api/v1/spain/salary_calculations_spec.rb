require "rails_helper"

RSpec.describe "Api::V1::Spain::SalaryCalculations", type: :request do
  describe "POST /api/v1/spain/salary_calculation" do
    it "returns a salary breakdown" do
      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            salary_period: "YEAR",
            tax_regime_key: "resident_employee_madrid"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "country_code")).to eq("ES")
      expect(json.dig("metadata", "tax_regime_key")).to eq("resident_employee_madrid")
      expect(json.dig("breakdown", "annual_net_income")).to be_within(0.01).of(42_236.36)
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
            tax_regime_key: "resident_self_employed_general"
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include(
        "Resident self-employed - general is stored in the rules database, but its calculator flow is not implemented yet."
      )
    end
  end
end
