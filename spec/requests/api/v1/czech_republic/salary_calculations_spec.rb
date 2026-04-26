require "rails_helper"

RSpec.describe "Api::V1::CzechRepublic::SalaryCalculations", type: :request do
  describe "POST /api/v1/czech_republic/salary_calculation" do
    it "returns an employee salary breakdown" do
      post api_v1_czech_republic_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 600_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_czech_republic",
            children_count: 1,
            disability_level: "invalidity_first_or_second_degree"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "country_code")).to eq("CZ")
      expect(json.dig("metadata", "tax_regime_key")).to eq("employee_czech_republic")
      expect(json.dig("breakdown", "taxpayer_credit")).to eq(30_840.0)
      expect(json["sources"]).not_to be_empty
    end

    it "matches a popular 2025 employee reference case for 45,000 CZK monthly gross with one child" do
      post api_v1_czech_republic_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 45_000,
            tax_year: 2025,
            salary_period: "MONTH",
            tax_regime_key: "employee_czech_republic",
            children_count: 1,
            disability_level: "none"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("breakdown", "monthly_net_income")).to eq(36_867.0)
      expect(json.dig("breakdown", "annual_net_income")).to eq(442_404.0)
    end

    it "accepts EUR input for Czech self-employed calculations and converts both income and expenses to CZK" do
      converter = Taxerase::Comparisons::EcbReferenceRateConverter.new
      converted_income = converter.convert(30_000, from_currency_code: "EUR", to_currency_code: "CZK")
      converted_expenses = converter.convert(5_000, from_currency_code: "EUR", to_currency_code: "CZK")
      expected_result = Taxerase::CzechRepublic::CalculationRouter.call(
        gross_income: converted_income,
        input_currency_code: "CZK",
        deductible_expenses: converted_expenses,
        expense_deduction_method: "actual_expenses",
        tax_year: 2025,
        salary_period: "YEAR",
        tax_regime_key: "self_employed_czech_republic",
        children_count: 0,
        disability_level: "none"
      )

      post api_v1_czech_republic_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 30_000,
            input_currency_code: "EUR",
            deductible_expenses: 5_000,
            expense_deduction_method: "actual_expenses",
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_czech_republic",
            children_count: 0,
            disability_level: "none"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("input", "input_currency_code")).to eq("EUR")
      expect(json.dig("metadata", "input_currency_code")).to eq("EUR")
      expect(json.dig("metadata", "display_currency_code")).to eq("EUR")
      expect(json["assumptions"].first).to include("converted to CZK")
      expect(json["assumptions"][1]).to include("converted back to EUR")
      expect(json.dig("input", "gross_income")).to eq(30_000.0)
      expect(json.dig("input", "deductible_expenses")).to eq(5_000.0)
      expect(json.dig("breakdown", "annual_net_income")).to eq(
        converter.convert_to_eur(expected_result.dig(:breakdown, :annual_net_income), "CZK")
      )
    end

    it "caps employee social security at the official annual maximum assessment base" do
      post api_v1_czech_republic_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 3_000_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_czech_republic",
            children_count: 0,
            disability_level: "none"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("breakdown", "annual_social_security")).to eq(158_666.26)
    end

    it "returns a self-employed breakdown" do
      post api_v1_czech_republic_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 900_000,
            deductible_expenses: 250_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_czech_republic",
            children_count: 2,
            disability_level: "ztp_p"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "tax_regime_key")).to eq("self_employed_czech_republic")
      expect(json.dig("breakdown", "annual_deductible_expenses")).to eq(250_000.0)
      expect(json.dig("breakdown", "annual_social_security")).to be > 0
      expect(json.dig("breakdown", "annual_health_contribution")).to be > 0
    end

    it "supports the 60% flat expense method for self-employed" do
      post api_v1_czech_republic_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 900_000,
            deductible_expenses: 1,
            expense_deduction_method: "flat_expense_60",
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_czech_republic",
            children_count: 0,
            disability_level: "none"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("input", "expense_deduction_method")).to eq("flat_expense_60")
      expect(json.dig("breakdown", "annual_deductible_expenses")).to eq(540_000.0)
      expect(json.dig("breakdown", "annual_net_income")).to eq(
        900_000.0 - json.dig("breakdown", "total_tax")
      )
      expect(json["detail_cards"].first["label"]).to eq("Deemed tax expenses (60%)")
      expect(json["assumptions"]).to include(
        "The selected flat-expense amount is a deemed tax deduction. It reduces taxable profit and contribution bases, but it is not treated as cash spent in the annual net-income metric."
      )
    end

    it "supports Czech spouse credit and non-taxable base deductions" do
      payload = {
        gross_income: 900_000,
        tax_year: 2025,
        salary_period: "YEAR",
        tax_regime_key: "employee_czech_republic",
        children_count: 1,
        disability_level: "none"
      }

      post api_v1_czech_republic_salary_calculation_path,
        params: { calculation: payload },
        as: :json

      expect(response).to have_http_status(:ok)

      baseline = JSON.parse(response.body)

      post api_v1_czech_republic_salary_calculation_path,
        params: {
          calculation: payload.merge(
            apply_spouse_credit: true,
            spouse_income: 20_000,
            spouse_cares_child_under_three: true,
            mortgage_interest_paid: 200_000,
            pension_contributions: 30_000,
            life_insurance_contributions: 30_000,
            donations_amount: 50_000
          )
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("breakdown", "spouse_credit")).to eq(24_840.0)
      expect(json.dig("breakdown", "non_taxable_deductions")).to eq(248_000.0)
      expect(json.dig("breakdown", "annual_income_tax")).to be < baseline.dig("breakdown", "annual_income_tax")
    end

    it "supports expanded Czech flat expense methods and caps" do
      post api_v1_czech_republic_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 3_000_000,
            deductible_expenses: 0,
            expense_deduction_method: "flat_expense_80",
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_czech_republic",
            children_count: 0,
            disability_level: "none"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("input", "expense_deduction_method")).to eq("flat_expense_80")
      expect(json.dig("breakdown", "annual_deductible_expenses")).to eq(1_600_000.0)
      expect(json["detail_cards"].first["label"]).to eq("Deemed tax expenses (80%)")
    end

    it "applies OSVC activity status variants to self-employed contribution minimums" do
      payload = {
        gross_income: 120_000,
        deductible_expenses: 0,
        expense_deduction_method: "actual_expenses",
        tax_year: 2025,
        salary_period: "YEAR",
        tax_regime_key: "self_employed_czech_republic",
        children_count: 0,
        disability_level: "none"
      }

      post api_v1_czech_republic_salary_calculation_path,
        params: { calculation: payload.merge(osvc_activity_status: "main") },
        as: :json

      expect(response).to have_http_status(:ok)

      main_activity = JSON.parse(response.body)

      post api_v1_czech_republic_salary_calculation_path,
        params: { calculation: payload.merge(osvc_activity_status: "secondary") },
        as: :json

      expect(response).to have_http_status(:ok)

      secondary_activity = JSON.parse(response.body)

      expect(main_activity.dig("breakdown", "annual_social_security")).to be > secondary_activity.dig("breakdown", "annual_social_security")
      expect(main_activity.dig("breakdown", "annual_health_contribution")).to be > secondary_activity.dig("breakdown", "annual_health_contribution")
    end

    it "supports Czech pausalni dan fixed-payment bands" do
      post api_v1_czech_republic_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 900_000,
            deductible_expenses: 0,
            expense_deduction_method: "flat_expense_60",
            self_employed_tax_mode: "pausal_band_1",
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_czech_republic",
            children_count: 2,
            disability_level: "ztp_p"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("input", "self_employed_tax_mode")).to eq("pausal_band_1")
      expect(json.dig("breakdown", "annual_income_tax")).to eq(1200.0)
      expect(json.dig("breakdown", "annual_social_security")).to eq(65_676.0)
      expect(json.dig("breakdown", "annual_health_contribution")).to eq(37_716.0)
      expect(json.dig("breakdown", "taxpayer_credit")).to eq(0.0)
      expect(json.dig("breakdown", "child_credit")).to eq(0.0)
    end

    it "caps Czech 60% flat expenses at CZK 1,200,000 a year" do
      post api_v1_czech_republic_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 3_000_000,
            deductible_expenses: 0,
            expense_deduction_method: "flat_expense_60",
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_czech_republic",
            children_count: 0,
            disability_level: "none"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("breakdown", "annual_deductible_expenses")).to eq(1_200_000.0)
      expect(json.dig("breakdown", "annual_net_income")).to eq(
        3_000_000.0 - json.dig("breakdown", "total_tax")
      )
    end

    it "caps self-employed social security at the official annual maximum assessment base" do
      post api_v1_czech_republic_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 5_000_000,
            deductible_expenses: 0,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_czech_republic",
            children_count: 0,
            disability_level: "none"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("breakdown", "annual_social_security")).to eq(652_542.91)
    end

    it "pays a child tax bonus only after the statutory annual qualifying income threshold is met" do
      post api_v1_czech_republic_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 10_000,
            tax_year: 2025,
            salary_period: "MONTH",
            tax_regime_key: "employee_czech_republic",
            children_count: 3,
            disability_level: "none"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("breakdown", "annual_child_tax_bonus")).to eq(0.0)
      expect(json.dig("breakdown", "annual_income_tax")).to eq(0.0)
    end

    it "returns validation errors for invalid input" do
      post api_v1_czech_republic_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 0,
            deductible_expenses: -1,
            expense_deduction_method: "actual_expenses",
            tax_year: 2025,
            salary_period: "DAY",
            tax_regime_key: "self_employed_czech_republic",
            children_count: -1,
            disability_level: "unknown"
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include("gross_income must be a number greater than 0")
      expect(json["errors"]).to include("deductible_expenses must be 0 or greater")
      expect(json["errors"]).to include("salary_period must be YEAR or MONTH")
      expect(json["errors"]).to include(
        "disability_level must be one of: none, invalidity_first_or_second_degree, invalidity_third_degree, ztp_p"
      )
    end

    it "returns a validation error for an unsupported Czech self-employed expense method" do
      post api_v1_czech_republic_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 500_000,
            deductible_expenses: 0,
            expense_deduction_method: "unsupported",
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_czech_republic",
            children_count: 0,
            disability_level: "none"
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include(
        "expense_deduction_method must be one of: actual_expenses, flat_expense_80, flat_expense_60, flat_expense_40, flat_expense_30"
      )
    end
  end
end
