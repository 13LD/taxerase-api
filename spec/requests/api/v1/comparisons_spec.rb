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
      expect(json["summary_metrics"].map { |metric| metric["key"] }).to eq(
        %w[annual_net_income monthly_net_income effective_tax_rate total_tax]
      )
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
  end
end
