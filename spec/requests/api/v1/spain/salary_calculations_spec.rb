require "rails_helper"

RSpec.describe "Api::V1::Spain::SalaryCalculations", type: :request do
  describe "POST /api/v1/spain/salary_calculation" do
    it "returns an employee salary breakdown" do
      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_madrid"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "country_code")).to eq("ES")
      expect(json.dig("metadata", "tax_regime_key")).to eq("employee_madrid")
      expect(json.dig("metadata", "tax_year")).to eq(2025)
      expect(json.dig("breakdown", "annual_net_income")).to be_within(0.01).of(42_236.36)
      expect(json["sources"]).not_to be_empty
      expect(json["rule_statuses"]).to include(
        a_hash_including(
          "status" => "needs_review",
          "status_label" => "Needs review",
          "label" => "Documented rule needs review",
          "message" => include("No union dues, ascendants, joint filing")
        )
      )
    end

    it "applies age, children, and disability inputs to the employee profile" do
      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_madrid"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)
      baseline = JSON.parse(response.body)

      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_madrid",
            age_bracket: "age_75_plus",
            children_count: 2,
            children_under_three_count: 1,
            disability_level: "level_65_plus"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("input", "age_bracket")).to eq("age_75_plus")
      expect(json.dig("input", "children_count")).to eq(2)
      expect(json.dig("input", "children_under_three_count")).to eq(1)
      expect(json.dig("input", "disability_level")).to eq("level_65_plus")
      expect(json.dig("breakdown", "state_personal_and_family_minimum")).to eq(28_000.0)
      expect(json.dig("breakdown", "annual_income_tax")).to be < baseline.dig("breakdown", "annual_income_tax")
      expect(json.dig("breakdown", "annual_net_income")).to be > baseline.dig("breakdown", "annual_net_income")
    end

    it "returns a 2024 employee salary breakdown" do
      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2024,
            salary_period: "YEAR",
            tax_regime_key: "employee_madrid"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "tax_regime_key")).to eq("employee_madrid")
      expect(json.dig("metadata", "tax_year")).to eq(2024)
      expect(json.dig("breakdown", "annual_net_income")).to be > 0
      expect(json["sources"]).not_to be_empty
    end

    it "returns a self-employed breakdown" do
      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            deductible_expenses: 10_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_madrid"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "tax_regime_key")).to eq("self_employed_madrid")
      expect(json.dig("metadata", "tax_year")).to eq(2025)
      expect(json.dig("breakdown", "annual_deductible_expenses")).to eq(10_000.0)
      expect(json.dig("breakdown", "annual_net_income")).to be_within(0.01).of(34_405.84)
    end

    it "returns a Beckham Law breakdown for Madrid" do
      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "beckham_madrid",
            age_bracket: "age_75_plus",
            children_count: 2,
            children_under_three_count: 1,
            disability_level: "level_65_plus"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "tax_regime_key")).to eq("beckham_madrid")
      expect(json.dig("metadata", "region")).to eq("Madrid")
      expect(json.dig("breakdown", "annual_income_tax")).to eq(14_400.0)
      expect(json.dig("breakdown", "annual_social_security")).to eq(3817.63)
      expect(json.dig("breakdown", "annual_net_income")).to eq(41_782.37)
      expect(json.dig("input", "age_bracket")).to eq("age_75_plus")
      expect(json.dig("input", "children_count")).to eq(2)
      expect(json.dig("detail_cards", 0, "label")).to eq("Beckham Law income tax")
      expect(json["sources"]).not_to be_empty
    end

    it "returns the same Beckham Law tax outcome across supported Spain regions" do
      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "beckham_andalusia"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)
      andalusia = JSON.parse(response.body)

      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "beckham_madrid"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)
      madrid = JSON.parse(response.body)

      expect(andalusia.dig("metadata", "region")).to eq("Andalusia")
      expect(madrid.dig("metadata", "region")).to eq("Madrid")
      expect(andalusia.dig("breakdown", "annual_net_income")).to eq(madrid.dig("breakdown", "annual_net_income"))
      expect(andalusia.dig("breakdown", "annual_income_tax")).to eq(madrid.dig("breakdown", "annual_income_tax"))
    end

    it "returns a 2024 self-employed breakdown" do
      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            deductible_expenses: 10_000,
            tax_year: 2024,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_madrid"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "tax_regime_key")).to eq("self_employed_madrid")
      expect(json.dig("metadata", "tax_year")).to eq(2024)
      expect(json.dig("breakdown", "annual_deductible_expenses")).to eq(10_000.0)
      expect(json.dig("breakdown", "annual_net_income")).to be > 0
    end

    it "returns a year-scoped unsupported message for source-backed foral regimes" do
      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2024,
            salary_period: "YEAR",
            tax_regime_key: "employee_navarre"
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include(
        "Resident employee - Navarre has official sources linked for 2024, but its calculator flow is not implemented yet."
      )
      expect(json["rule_statuses"]).to contain_exactly(
        a_hash_including(
          "status" => "not_implemented",
          "status_label" => "Not implemented",
          "rule_key" => "employee_navarre:2024:calculator_flow",
          "label" => "Resident employee - Navarre calculator flow",
          "message" => "Resident employee - Navarre has official sources linked for 2024, but its calculator flow is not implemented yet."
        )
      )
    end

    it "returns validation errors for invalid input" do
      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 0,
            tax_year: 2025,
            salary_period: "DAY",
            tax_regime_key: "employee_madrid",
            children_count: 1,
            children_under_three_count: 2
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include("gross_income must be a number greater than 0")
      expect(json["errors"]).to include("salary_period must be YEAR or MONTH")
      expect(json["errors"]).to include("children_under_three_count must be an integer between 0 and children_count")
    end

    it "returns a clear error for unsupported regimes" do
      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2025,
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
      expect(json["rule_statuses"]).to contain_exactly(
        a_hash_including(
          "status" => "not_implemented",
          "rule_key" => "corporate_income_general:2025:calculator_flow",
          "label" => "Corporate income tax - general calculator flow"
        )
      )
    end
  end
end
