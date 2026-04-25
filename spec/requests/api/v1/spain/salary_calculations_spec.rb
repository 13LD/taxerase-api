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
      expect(json.dig("breakdown", "annual_net_income")).to be_within(0.01).of(42_229.96)
      expect(json["sources"]).not_to be_empty
      expect(json["rule_statuses"]).to include(
        a_hash_including(
          "status" => "needs_review",
          "status_label" => "Needs review",
          "label" => "Documented rule needs review",
          "message" => include("Regional deductions")
        )
      )
    end

    it "applies ascendant minimums and ascendant disability minimums" do
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
      baseline = JSON.parse(response.body)

      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_madrid",
            ascendants_count: 1,
            ascendants_over_75_count: 1,
            ascendant_disability_65_count: 1,
            ascendant_disability_support_count: 1
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json.dig("input", "ascendants_count")).to eq(1)
      expect(json.dig("input", "ascendants_over_75_count")).to eq(1)
      expect(json.dig("breakdown", "state_personal_and_family_minimum")).to be > baseline.dig("breakdown", "state_personal_and_family_minimum")
      expect(json.dig("breakdown", "annual_income_tax")).to be < baseline.dig("breakdown", "annual_income_tax")
    end

    it "applies national family deductions in the differential quota" do
      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_madrid",
            maternity_eligible_months: 12,
            nursery_expenses_paid: 1500,
            large_family_category: "general",
            large_family_extra_children: 1,
            single_parent_two_children: true,
            disabled_descendants_count: 1,
            disabled_ascendants_count: 1,
            spouse_disability_dependant: true
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json.dig("breakdown", "national_family_deductions")).to eq(8_800.0)
      expect(json.dig("detail_cards").map { |card| card["label"] }).to include("National family deductions")
    end

    it "applies joint filing and employment-specific deductible expenses" do
      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_madrid",
            joint_filing_mode: "married_unit",
            union_dues: 240,
            professional_fees: 800,
            legal_defense_costs: 500,
            disabled_worker_status: "level_65_plus_or_support",
            geographic_mobility: true
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json.dig("breakdown", "additional_employee_expenses")).to eq(10_790.0)
      expect(json.dig("breakdown", "joint_filing_reduction")).to eq(3_400.0)
      expect(json.dig("input", "professional_fees")).to eq(800.0)
      expect(json.dig("input", "disabled_worker_status")).to eq("level_65_plus_or_support")
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

    it "applies direct-normal self-employed home-office and meal expense classes" do
      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            deductible_expenses: 10_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_madrid",
            self_employed_estimation_method: "direct_normal",
            home_office_supply_expenses: 1200,
            home_office_ownership_expenses: 2400,
            home_office_business_use_percentage: 25,
            meals_expenses: 800
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json.dig("input", "self_employed_estimation_method")).to eq("direct_normal")
      expect(json.dig("breakdown", "home_office_supply_deduction")).to eq(90.0)
      expect(json.dig("breakdown", "home_office_ownership_deduction")).to eq(600.0)
      expect(json.dig("breakdown", "meals_deduction")).to eq(800.0)
      expect(json.dig("breakdown", "difficult_to_justify_deduction")).to eq(0.0)
    end

    it "supports modules estimate and RETA reduced quota overlays" do
      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            deductible_expenses: 10_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_madrid",
            self_employed_estimation_method: "modules",
            meals_expenses: 800,
            reta_contribution_mode: "reduced_first_year"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json.dig("input", "self_employed_estimation_method")).to eq("modules")
      expect(json.dig("breakdown", "annual_deductible_expenses")).to eq(0.0)
      expect(json.dig("breakdown", "meals_deduction")).to eq(0.0)
      expect(json.dig("breakdown", "net_income_before_social_security")).to eq(18_000.0)
      expect(json.dig("breakdown", "annual_social_security")).to eq(960.0)
      expect(json["assumptions"]).to include(match(/80 EUR reduced RETA quota/))
    end

    it "rejects overlapping ascendant disability counts" do
      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_madrid",
            ascendants_count: 1,
            ascendant_disability_33_count: 1,
            ascendant_disability_65_count: 1
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include("ascendant disability counts must not exceed ascendants_count")
    end

    it "applies RETA pluriactivity, family collaborator, and corporate self-employed overlays" do
      post api_v1_spain_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 100_000,
            deductible_expenses: 10_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_madrid",
            family_collaborator: true,
            corporate_self_employed: true,
            apply_reta_pluriactivity: true,
            employment_common_contingencies_paid: 20_000
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json.dig("input", "family_collaborator")).to be(true)
      expect(json.dig("input", "corporate_self_employed")).to be(true)
      expect(json.dig("breakdown", "standard_social_security")).to be > json.dig("breakdown", "annual_social_security")
      expect(json.dig("breakdown", "reta_pluriactivity_refund")).to be > 0
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
