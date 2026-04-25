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

    it "applies documented employee credits and fiscal-partner IACK logic" do
      post api_v1_netherlands_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 30_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_netherlands",
            age_bracket: "under_aow_age",
            fiscal_partner: true,
            partner_labour_income: 45_000,
            children_under_12_count: 1,
            wajong_status: true,
            green_investments_value: 30_000
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("input", "fiscal_partner")).to be(true)
      expect(json.dig("breakdown", "income_dependent_combination_credit")).to be > 0
      expect(json.dig("breakdown", "young_disabled_credit")).to eq(909.0)
      expect(json.dig("breakdown", "green_investment_credit")).to eq(30.0)
      expect(json.dig("breakdown", "total_tax_credits")).to be > (
        json.dig("breakdown", "general_tax_credit") + json.dig("breakdown", "labour_tax_credit")
      )
    end

    it "applies older-person credits for single AOW households" do
      post api_v1_netherlands_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 35_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_netherlands",
            age_bracket: "aow_age_or_older",
            single_aow_household: true
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("breakdown", "older_person_credit")).to eq(2_035.0)
      expect(json.dig("breakdown", "single_older_person_credit")).to eq(531.0)
    end

    it "applies personal deductions and carries forward the unused remainder" do
      post api_v1_netherlands_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 10_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_netherlands",
            age_bracket: "under_aow_age",
            partner_alimony_paid: 5_000,
            deductible_lijfrente_premium: 2_000,
            remaining_personal_deduction_carryforward: 20_000
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("breakdown", "personal_deductions")).to eq(10_000.0)
      expect(json.dig("breakdown", "taxable_income_after_deductions")).to eq(0.0)
      expect(json.dig("breakdown", "remaining_personal_deduction_carryforward")).to eq(17_000.0)
      expect(json.dig("breakdown", "personal_deduction_components", "partner_alimony")).to eq(5_000.0)
    end

    it "calculates the documented personal deduction components" do
      post api_v1_netherlands_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 30_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_netherlands",
            age_bracket: "under_aow_age",
            healthcare_medicines_prescription: 1_000,
            temporary_home_stay_disabled_days: 10,
            temporary_home_stay_disabled_km: 100,
            ordinary_anbi_gifts: 1_000,
            periodic_anbi_gifts: 500,
            cultural_anbi_gifts: 200,
            deductible_aov_premium: 600,
            deductible_lijfrente_premium: 700
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      components = json.dig("breakdown", "personal_deduction_components")

      expect(components["healthcare_costs"]).to eq(905.0)
      expect(components["temporary_home_stay_disabled"]).to eq(153.0)
      expect(components["gifts"]).to eq(1_450.0)
      expect(components["aov_premiums"]).to eq(600.0)
      expect(components["lijfrente_premiums"]).to eq(700.0)
    end

    it "ignores partner income for deduction thresholds when fiscal partner is not selected" do
      post api_v1_netherlands_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 30_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_netherlands",
            age_bracket: "under_aow_age",
            fiscal_partner: false,
            partner_labour_income: 100_000,
            healthcare_medicines_prescription: 1_000
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("input", "fiscal_partner")).to be(false)
      expect(json.dig("breakdown", "personal_deduction_components", "healthcare_costs")).to eq(905.0)
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

    it "ignores stale cessation annuity premiums unless the business has ceased" do
      post api_v1_netherlands_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 80_000,
            deductible_expenses: 10_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_netherlands",
            age_bracket: "under_aow_age",
            business_ceased: false,
            cessation_annuity_premium: 4_000
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("input", "cessation_annuity_premium")).to eq(0.0)
      expect(json.dig("breakdown", "personal_deduction_components", "cessation_annuity_premiums")).to eq(0.0)
    end

    it "models entrepreneur eligibility instead of always applying reliefs" do
      post api_v1_netherlands_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            deductible_expenses: 10_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_netherlands",
            age_bracket: "under_aow_age",
            qualifies_as_entrepreneur: false,
            hours_worked_in_business: 400
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("breakdown", "entrepreneur_eligibility", "entrepreneur")).to be(false)
      expect(json.dig("breakdown", "entrepreneur_eligibility", "hours_criterion_met")).to be(false)
      expect(json.dig("breakdown", "self_employed_deduction")).to eq(0.0)
    end

    it "applies the documented self-employed relief and expense layers" do
      post api_v1_netherlands_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 100_000,
            deductible_expenses: 10_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_netherlands",
            age_bracket: "under_aow_age",
            fiscal_partner: true,
            partner_unpaid_hours: 900,
            partner_fee_paid: 0,
            startup_uses_in_last_5_years: 0,
            has_s_and_o_declaration: true,
            s_and_o_hours: 600,
            s_and_o_starter: true,
            business_ceased: true,
            cessation_profit: 10_000,
            private_vehicle_business_km: 1_000,
            limited_deductible_costs_amount: 10_000,
            choose_80_percent_method: true,
            kia_basis: 10_000,
            home_workspace_independent: true,
            home_workspace_costs: 1_200,
            cessation_annuity_premium: 4_000
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      reliefs = json.dig("breakdown", "entrepreneur_relief_components")
      expenses = json.dig("breakdown", "expense_components")

      expect(expenses["private_vehicle_km"]).to eq(230.0)
      expect(expenses["mixed_costs"]).to eq(8_000.0)
      expect(expenses["home_workspace"]).to eq(1_200.0)
      expect(reliefs["starters_deduction"]).to eq(2_123.0)
      expect(reliefs["s_and_o_deduction"]).to eq(23_613.0)
      expect(reliefs["meewerkaftrek"]).to be > 0
      expect(reliefs["stakingsaftrek"]).to eq(3_630.0)
      expect(reliefs["kia"]).to eq(2_800.0)
      expect(json.dig("breakdown", "personal_deduction_components", "cessation_annuity_premiums")).to eq(4_000.0)
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

    it "rejects advanced Netherlands inputs for unsupported 2024 rules" do
      post api_v1_netherlands_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2024,
            salary_period: "YEAR",
            tax_regime_key: "employee_netherlands",
            age_bracket: "under_aow_age",
            wajong_status: true
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include(
        "Netherlands credit, personal deduction, and entrepreneur detail inputs are currently supported only for tax year 2025"
      )
    end

    it "rejects blank advanced Netherlands inputs for unsupported 2024 rules" do
      post api_v1_netherlands_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            deductible_expenses: 10_000,
            tax_year: 2024,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_netherlands",
            age_bracket: "under_aow_age",
            qualifies_as_entrepreneur: "",
            hours_worked_in_business: ""
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include(
        "Netherlands credit, personal deduction, and entrepreneur detail inputs are currently supported only for tax year 2025"
      )
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
