require "rails_helper"

RSpec.describe "Api::V1::Poland::SalaryCalculations", type: :request do
  describe "POST /api/v1/poland/salary_calculation" do
    it "returns an employee salary breakdown" do
      post api_v1_poland_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 120_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_poland",
            age_bracket: "age_26_to_retirement",
            children_count: 2
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "country_code")).to eq("PL")
      expect(json.dig("metadata", "tax_regime_key")).to eq("employee_poland")
      expect(json.dig("metadata", "tax_regime_name")).to eq("Contract of employment - Poland")
      expect(json.dig("breakdown", "annual_net_income")).to be > 0
      expect(json["sources"]).not_to be_empty
    end

    it "applies Poland's special PIT exemption family to employee income" do
      post api_v1_poland_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 120_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_poland",
            age_bracket: "age_26_to_retirement",
            children_count: 0
          }
        },
        as: :json

      baseline = JSON.parse(response.body)

      post api_v1_poland_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 120_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_poland",
            age_bracket: "age_26_to_retirement",
            children_count: 0,
            apply_return_relief: true,
            return_relief_prior_non_resident: true,
            return_relief_year: 1
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("breakdown", "special_relief_exempt_income")).to eq(85_528.0)
      expect(json.dig("breakdown", "annual_income_tax")).to be <= baseline.dig("breakdown", "annual_income_tax")
      expect(json.dig("input", "apply_return_relief")).to be(true)
      expect(json["detail_cards"]).to include(include("label" => "Special PIT exemption income"))
    end

    it "accepts EUR input for Poland and converts it to PLN before calculation" do
      converter = Taxerase::Comparisons::EcbReferenceRateConverter.new
      converted_income = converter.convert(10_000, from_currency_code: "EUR", to_currency_code: "PLN")
      expected_result = Taxerase::Poland::CalculationRouter.call(
        gross_income: converted_income,
        input_currency_code: "PLN",
        tax_year: 2025,
        salary_period: "YEAR",
        tax_regime_key: "employee_poland",
        age_bracket: "age_26_to_retirement",
        children_count: 0
      )

      post api_v1_poland_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 10_000,
            input_currency_code: "EUR",
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_poland",
            age_bracket: "age_26_to_retirement",
            children_count: 0
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("input", "input_currency_code")).to eq("EUR")
      expect(json.dig("metadata", "input_currency_code")).to eq("EUR")
      expect(json.dig("metadata", "display_currency_code")).to eq("EUR")
      expect(json["assumptions"].first).to include("converted to PLN")
      expect(json["assumptions"][1]).to include("converted back to EUR")
      expect(json.dig("input", "gross_income")).to eq(10_000.0)
      expect(json.dig("breakdown", "annual_net_income")).to eq(
        converter.convert_to_eur(expected_result.dig(:breakdown, :annual_net_income), "PLN")
      )
    end

    it "returns a self-employed breakdown" do
      post api_v1_poland_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 180_000,
            deductible_expenses: 35_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_poland",
            age_bracket: "age_26_to_retirement",
            children_count: 1
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("metadata", "tax_regime_key")).to eq("self_employed_poland")
      expect(json.dig("metadata", "tax_regime_name")).to eq("B2B contract - Poland")
      expect(json.dig("breakdown", "annual_deductible_expenses")).to eq(35_000.0)
      expect(json.dig("breakdown", "annual_social_security")).to be > 0
      expect(json.dig("breakdown", "annual_health_contribution")).to be > 0
      expect(json.dig("breakdown", "annual_invoice_total_with_vat")).to be_nil
      expect(json.dig("input", "vat_rate")).to be_nil
    end

    it "uses structured young-worker eligibility instead of only the broad age bucket" do
      employee_payload = {
        gross_income: 120_000,
        tax_year: 2025,
        salary_period: "YEAR",
        tax_regime_key: "employee_poland",
        age_bracket: "age_26_to_retirement",
        birth_year: 2002,
        young_worker_relief_income_type: "employment",
        children_count: 0
      }

      post api_v1_poland_salary_calculation_path,
        params: { calculation: employee_payload },
        as: :json

      expect(response).to have_http_status(:ok)

      eligible = JSON.parse(response.body)

      post api_v1_poland_salary_calculation_path,
        params: { calculation: employee_payload.merge(young_worker_relief_income_type: "other") },
        as: :json

      expect(response).to have_http_status(:ok)

      ineligible = JSON.parse(response.body)

      expect(eligible.dig("breakdown", "special_relief_exempt_income")).to eq(85_528.0)
      expect(ineligible.dig("breakdown", "special_relief_exempt_income")).to eq(0.0)
      expect(eligible.dig("breakdown", "annual_income_tax")).to be < ineligible.dig("breakdown", "annual_income_tax")
    end

    it "applies one-child household limits and claim-share allocation" do
      base_payload = {
        gross_income: 80_000,
        tax_year: 2025,
        salary_period: "YEAR",
        tax_regime_key: "employee_poland",
        age_bracket: "age_26_to_retirement",
        children_count: 1,
        child_relief_household_status: "single",
        child_relief_household_income: 80_000
      }

      post api_v1_poland_salary_calculation_path,
        params: { calculation: base_payload.merge(child_relief_claim_share: 100) },
        as: :json

      expect(response).to have_http_status(:ok)

      over_limit = JSON.parse(response.body)

      post api_v1_poland_salary_calculation_path,
        params: { calculation: base_payload.merge(child_relief_household_income: 40_000, child_relief_claim_share: 50) },
        as: :json

      expect(response).to have_http_status(:ok)

      shared_claim = JSON.parse(response.body)

      expect(over_limit.dig("breakdown", "annual_child_relief")).to eq(0.0)
      expect(shared_claim.dig("breakdown", "annual_child_relief")).to eq(556.02)
    end

    it "infers one-child threshold income when the UI submits the default zero household income" do
      post api_v1_poland_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 80_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_poland",
            age_bracket: "age_26_to_retirement",
            children_count: 1,
            child_relief_household_status: "single",
            child_relief_household_income: 0,
            child_relief_claim_share: 100
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("input", "child_relief_household_income")).to eq(0.0)
      expect(json.dig("breakdown", "annual_child_relief")).to eq(0.0)
    end

    it "applies simplified joint-spouse filing before child relief" do
      payload = {
        gross_income: 220_000,
        tax_year: 2025,
        salary_period: "YEAR",
        tax_regime_key: "employee_poland",
        age_bracket: "age_26_to_retirement",
        children_count: 0
      }

      post api_v1_poland_salary_calculation_path,
        params: { calculation: payload.merge(filing_status: "individual") },
        as: :json

      expect(response).to have_http_status(:ok)

      individual = JSON.parse(response.body)

      post api_v1_poland_salary_calculation_path,
        params: { calculation: payload.merge(filing_status: "joint_spouse", spouse_income: 0) },
        as: :json

      expect(response).to have_http_status(:ok)

      joint = JSON.parse(response.body)
      regime = TaxRegime
        .for_country_year(country: Country.find_by!(code: "PL"), tax_year: 2025)
        .find_by!(key: "employee_poland")
      quotient_tax = Taxerase::Poland::ProgressiveTax.call(
        amount: BigDecimal(joint.dig("breakdown", "annual_taxable_income").to_s) / 2,
        brackets: regime.brackets_for("pit_scale")
      )
      expected_joint_tax_before_reliefs =
        ([ quotient_tax - regime.parameter_decimal!("annual_tax_reducing_amount"), 0 ].max * 2).round(2).to_f

      expect(joint.dig("input", "filing_status")).to eq("joint_spouse")
      expect(joint.dig("breakdown", "annual_income_tax_before_reliefs")).to eq(expected_joint_tax_before_reliefs)
      expect(joint.dig("breakdown", "annual_income_tax")).to be < individual.dig("breakdown", "annual_income_tax")
    end

    it "applies the one-child income threshold to tax-scale B2B child relief" do
      post api_v1_poland_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 180_000,
            deductible_expenses: 0,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_poland",
            age_bracket: "age_26_to_retirement",
            children_count: 1,
            b2b_tax_form: "tax_scale"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("breakdown", "annual_child_relief")).to eq(0.0)
    end

    it "maps lump-sum B2B activity type to the seeded ryczalt rate" do
      payload = {
        gross_income: 180_000,
        deductible_expenses: 0,
        tax_year: 2025,
        salary_period: "YEAR",
        tax_regime_key: "self_employed_poland",
        age_bracket: "age_26_to_retirement",
        children_count: 0,
        b2b_tax_form: "lump_sum",
        months_since_business_start: 37
      }

      post api_v1_poland_salary_calculation_path,
        params: { calculation: payload.merge(lump_sum_activity_type: "it_services") },
        as: :json

      expect(response).to have_http_status(:ok)

      it_services = JSON.parse(response.body)

      post api_v1_poland_salary_calculation_path,
        params: { calculation: payload.merge(lump_sum_activity_type: "trade_gastronomy") },
        as: :json

      expect(response).to have_http_status(:ok)

      trade = JSON.parse(response.body)

      expect(it_services.dig("input", "lump_sum_rate")).to eq(12.0)
      expect(trade.dig("input", "lump_sum_rate")).to eq(3.0)
      expect(trade.dig("breakdown", "annual_income_tax")).to be < it_services.dig("breakdown", "annual_income_tax")
    end

    it "returns validation errors for unsupported lump-sum activity types" do
      post api_v1_poland_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 180_000,
            deductible_expenses: 0,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "self_employed_poland",
            age_bracket: "age_26_to_retirement",
            children_count: 0,
            b2b_tax_form: "lump_sum",
            lump_sum_activity_type: "unknown_activity",
            months_since_business_start: 37
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include(
        "lump_sum_activity_type must be one of: professional_services, healthcare, it_services, general_services, manufacturing_construction, trade_gastronomy"
      )
    end

    it "uses start timeline and cooperating-person status for B2B ZUS mode" do
      payload = {
        gross_income: 180_000,
        deductible_expenses: 0,
        tax_year: 2025,
        salary_period: "YEAR",
        tax_regime_key: "self_employed_poland",
        age_bracket: "age_26_to_retirement",
        children_count: 0,
        b2b_tax_form: "flat_tax"
      }

      post api_v1_poland_salary_calculation_path,
        params: { calculation: payload.merge(months_since_business_start: 3, cooperating_person: false) },
        as: :json

      expect(response).to have_http_status(:ok)

      start_relief = JSON.parse(response.body)

      post api_v1_poland_salary_calculation_path,
        params: { calculation: payload.merge(months_since_business_start: 3, cooperating_person: true) },
        as: :json

      expect(response).to have_http_status(:ok)

      cooperating = JSON.parse(response.body)

      expect(start_relief.dig("breakdown", "annual_social_security")).to eq(0.0)
      expect(cooperating.dig("breakdown", "annual_social_security")).to be > 0
    end

    it "returns validation errors for invalid input" do
      post api_v1_poland_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 0,
            deductible_expenses: -1,
            tax_year: 2025,
            salary_period: "DAY",
            tax_regime_key: "self_employed_poland",
            age_bracket: "unknown",
            children_count: -1
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include("gross_income must be a number greater than 0")
      expect(json["errors"]).to include("deductible_expenses must be 0 or greater")
      expect(json["errors"]).to include("salary_period must be YEAR or MONTH")
      expect(json["errors"]).to include("age_bracket must be one of: under_26, age_26_to_retirement, retirement_age_or_older")
    end

    it "validates structured return and working-senior relief facts" do
      post api_v1_poland_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 120_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_poland",
            age_bracket: "retirement_age_or_older",
            children_count: 0,
            apply_return_relief: true,
            return_relief_prior_non_resident: false,
            return_relief_year: 0,
            apply_working_senior_relief: true,
            working_senior_receives_pension: true
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include("return relief requires prior non-residence eligibility")
      expect(json["errors"]).to include("return_relief_year must be between 1 and 4")
      expect(json["errors"]).to include("working senior relief requires not receiving a pension")
    end

    it "validates the family 4+ and working senior relief eligibility rules" do
      post api_v1_poland_salary_calculation_path,
        params: {
          calculation: {
            gross_income: 120_000,
            tax_year: 2025,
            salary_period: "YEAR",
            tax_regime_key: "employee_poland",
            age_bracket: "age_26_to_retirement",
            children_count: 2,
            apply_family_4plus_relief: true,
            apply_working_senior_relief: true
          }
        },
        as: :json

      expect(response).to have_http_status(:unprocessable_content)

      json = JSON.parse(response.body)

      expect(json["errors"]).to include("family 4+ relief requires at least 4 children")
      expect(json["errors"]).to include("working senior relief requires retirement age or older")
    end
  end
end
