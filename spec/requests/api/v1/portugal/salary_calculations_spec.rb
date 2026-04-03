require "rails_helper"

RSpec.describe "Api::V1::Portugal::SalaryCalculations", type: :request do
  describe "POST /api/v1/portugal/salary_calculation" do
    it "returns a 2024 employee salary breakdown" do
      post api_v1_portugal_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2024,
            salary_period: "YEAR",
            tax_regime_key: "employee_portugal",
            children_count: 0,
            children_under_three_count: 0,
            disability_level: "none"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "tax_year")).to eq(2024)
      expect(json.dig("breakdown", "specific_deduction")).to eq(6_600.0)
      expect(json["sources"]).not_to be_empty
    end

    it "returns an employee salary breakdown" do
      post api_v1_portugal_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 60_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_portugal",
            children_count: 1,
            children_under_three_count: 1,
            disability_level: "none",
            ascendants_count: 1,
            health_expenses: 1_000,
            education_expenses: 500
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "country_code")).to eq("PT")
      expect(json.dig("metadata", "tax_regime_key")).to eq("employee_portugal")
      expect(json.dig("breakdown", "annual_social_security")).to eq(6_600.0)
      expect(json.dig("breakdown", "dependent_deduction")).to eq(600.0)
      expect(json.dig("breakdown", "dependent_under_three_deduction")).to eq(126.0)
      expect(json.dig("breakdown", "ascendant_deduction")).to eq(635.0)
      expect(json.dig("breakdown", "health_expenses_deduction")).to eq(150.0)
      expect(json["sources"]).not_to be_empty
    end

    it "reduces employee IRS when personal deductions are added" do
      post api_v1_portugal_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 40_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_portugal",
            children_count: 0,
            children_under_three_count: 0,
            disability_level: "none"
          }
        },
        as: :json

      baseline = JSON.parse(response.body)

      post api_v1_portugal_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 40_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_portugal",
            children_count: 2,
            children_under_three_count: 1,
            disability_level: "disability_60_plus",
            ascendants_count: 1,
            general_family_expenses: 1_000,
            health_expenses: 2_000,
            education_expenses: 2_000,
            housing_rent: 10_000,
            alimony_paid: 3_000,
            care_home_expenses: 2_000,
            domestic_work_expenses: 5_000
          }
        },
        as: :json

      json = JSON.parse(response.body)

      expect(json.dig("breakdown", "annual_income_tax")).to be < baseline.dig("breakdown", "annual_income_tax")
      expect(json.dig("breakdown", "annual_net_income")).to be > baseline.dig("breakdown", "annual_net_income")
      expect(json.dig("breakdown", "taxable_income")).to eq(baseline.dig("breakdown", "taxable_income"))
    end

    it "returns a self-employed breakdown for professional services" do
      post api_v1_portugal_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 70_000,
            deductible_expenses: 0,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_portugal",
            business_activity_type: "professional_services",
            children_count: 1,
            children_under_three_count: 0,
            disability_level: "none",
            general_family_expenses: 800
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "tax_regime_key")).to eq("self_employed_portugal")
      expect(json.dig("input", "business_activity_type")).to eq("professional_services")
      expect(json.dig("breakdown", "annual_deductible_expenses")).to eq(0.0)
      expect(json.dig("breakdown", "documentation_shortfall_addition")).to be > 0
      expect(json.dig("breakdown", "annual_social_security")).to be > 0
      expect(json["sources"]).not_to be_empty
    end

    it "uses the lighter simplified coefficients for goods and hospitality activity" do
      post api_v1_portugal_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 70_000,
            deductible_expenses: 4_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_portugal",
            business_activity_type: "professional_services",
            children_count: 0,
            children_under_three_count: 0,
            disability_level: "none"
          }
        },
        as: :json

      professional_services = JSON.parse(response.body)

      post api_v1_portugal_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 70_000,
            deductible_expenses: 4_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_portugal",
            business_activity_type: "sales_goods_hospitality",
            children_count: 0,
            children_under_three_count: 0,
            disability_level: "none"
          }
        },
        as: :json

      goods_activity = JSON.parse(response.body)

      expect(goods_activity.dig("breakdown", "simplified_taxable_base")).to be < professional_services.dig("breakdown", "simplified_taxable_base")
      expect(goods_activity.dig("breakdown", "annual_social_security")).to be < professional_services.dig("breakdown", "annual_social_security")
      expect(goods_activity.dig("breakdown", "annual_net_income")).to be > professional_services.dig("breakdown", "annual_net_income")
    end

    it "returns validation errors for invalid input" do
      post api_v1_portugal_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 0,
            deductible_expenses: -1,
            tax_year: 2025,
            salary_period: "DAY",
            tax_regime_key: "self_employed_portugal",
            business_activity_type: "unknown",
            children_count: -1,
            children_under_three_count: 2,
            disability_level: "invalid",
            ascendants_count: -1,
            health_expenses: -5
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include("gross_income must be a number greater than 0")
      expect(json["errors"]).to include("deductible_expenses must be 0 or greater")
      expect(json["errors"]).to include("salary_period must be YEAR or MONTH")
      expect(json["errors"]).to include("business_activity_type must be one of: professional_services, other_services, sales_goods_hospitality")
      expect(json["errors"]).to include("disability_level must be one of: none, disability_60_plus")
      expect(json["errors"]).to include("ascendants_count must be 0 or greater")
      expect(json["errors"]).to include("health_expenses must be 0 or greater")
    end
  end
end
