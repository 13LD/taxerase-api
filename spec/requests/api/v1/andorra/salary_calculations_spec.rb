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

    it "applies the spouse-income phase-in and keeps housing support separate from tax" do
      post api_v1_andorra_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 55_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_andorra",
            has_spouse_or_partner: true,
            spouse_general_income: 10_980,
            apply_housing_rent_support: true,
            housing_support_priority_group: false,
            housing_rent: 12_000
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("breakdown", "taxpayer_reduction")).to eq(29_020.0)
      expect(json.dig("breakdown", "spouse_phase_in_increment")).to eq(5_020.0)
      expect(json.dig("breakdown", "annual_housing_rent_support_estimate")).to eq(3_600.0)
      expect(json.dig("detail_cards").map { |card| card["label"] }).to include("Housing rent support estimate (non-tax)")
      expect(json.dig("assumptions").join(" ")).to include("outside IRPF and CASS totals")
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

    it "supports the under-35 special self-employed CASS regime" do
      post api_v1_andorra_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 24_000,
            deductible_expenses: 4_000,
            tax_year: 2026,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_andorra",
            self_employed_social_security_regime: "under_35_first_12_months"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("breakdown", "self_employed_social_security_base_monthly")).to eq(838.93)
      expect(json.dig("breakdown", "annual_social_security")).to eq(1_006.72)
      expect(json.dig("breakdown", "annual_income_tax")).to eq(0.0)
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
            ascendants_count: -1,
            self_employed_social_security_regime: "invalid"
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
      expect(json["errors"]).to include("self_employed_social_security_regime must be one of: standard, under_35_first_12_months, under_35_month_13_to_24")
    end

    it "rejects spouse-specific inputs when no spouse or partner is selected" do
      post api_v1_andorra_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_andorra",
            has_spouse_or_partner: false,
            spouse_general_income: 5_000
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include("spouse inputs require has_spouse_or_partner to be true")
    end
  end
end
