module Taxerase
  module Portugal
    class CalculationRouter
      extend Taxerase::Support::CountryRouter

      class UnsupportedRegimeError < Taxerase::UnsupportedRegimeError; end

      COUNTRY_CODE = "PT".freeze
      NATIVE_CURRENCY_CODE = "EUR".freeze
      SUPPORTED_INPUT_CURRENCY_CODES = %w[EUR].freeze
      SUPPORTED_METHODS = {
        EmployeeCalculator::CALCULATION_METHOD => EmployeeCalculator,
        SelfEmployedCalculator::CALCULATION_METHOD => SelfEmployedCalculator
      }.freeze

      def self.call(
        gross_income:,
        salary_period:,
        tax_year:,
        tax_regime_key: nil,
        input_currency_code: NATIVE_CURRENCY_CODE,
        deductible_expenses: 0,
        age_bracket: "standard",
        children_count: 0,
        children_under_three_count: 0,
        disability_level: "none",
        business_activity_type: "professional_services",
        ascendants_count: 0,
        general_family_expenses: 0,
        health_expenses: 0,
        education_expenses: 0,
        housing_rent: 0,
        alimony_paid: 0,
        care_home_expenses: 0,
        domestic_work_expenses: 0,
        young_dependents_second_later_under_six_count: 0,
        vat_invoice_expenses: 0,
        vat_invoice_validation_state: "not_validated",
        disability_rehabilitation_expenses: 0,
        disability_insurance_premiums: 0,
        ppr_contributions: 0,
        ppr_age_band: "under_35",
        donations: 0,
        filing_status: "individual",
        apply_irs_jovem: false,
        irs_jovem_year: 0,
        union_dues: 0,
        professional_order_dues: 0,
        self_employed_tax_regime: "simplified",
        start_activity_year: "none",
        social_security_exemption: false,
        social_security_adjustment_mode: "standard"
      )
        resolved_input_currency_code = input_currency_handler.resolve_input_currency_code(input_currency_code)
        resolved_children_count = children_count.presence || 0
        resolved_children_under_three_count = children_under_three_count.presence || 0
        resolved_disability_level = disability_level.presence || "none"
        resolved_ascendants_count = ascendants_count.presence || 0
        resolved_general_family_expenses = general_family_expenses.presence || 0
        resolved_health_expenses = health_expenses.presence || 0
        resolved_education_expenses = education_expenses.presence || 0
        resolved_housing_rent = housing_rent.presence || 0
        resolved_alimony_paid = alimony_paid.presence || 0
        resolved_care_home_expenses = care_home_expenses.presence || 0
        resolved_domestic_work_expenses = domestic_work_expenses.presence || 0
        resolved_young_dependents_second_later_under_six_count =
          young_dependents_second_later_under_six_count.presence || 0
        resolved_vat_invoice_expenses = vat_invoice_expenses.presence || 0
        resolved_vat_invoice_validation_state = vat_invoice_validation_state.presence || "not_validated"
        resolved_disability_rehabilitation_expenses = disability_rehabilitation_expenses.presence || 0
        resolved_disability_insurance_premiums = disability_insurance_premiums.presence || 0
        resolved_ppr_contributions = ppr_contributions.presence || 0
        resolved_ppr_age_band = ppr_age_band.presence || "under_35"
        resolved_donations = donations.presence || 0
        resolved_filing_status = filing_status.presence || "individual"
        resolved_irs_jovem_year = irs_jovem_year.presence || 0
        resolved_union_dues = union_dues.presence || 0
        resolved_professional_order_dues = professional_order_dues.presence || 0
        normalized_gross_income = input_currency_handler.convert_amount(
          gross_income,
          input_currency_code: resolved_input_currency_code
        )
        normalized_deductible_expenses = input_currency_handler.convert_amount(
          deductible_expenses,
          input_currency_code: resolved_input_currency_code
        )
        regime = regime_for!(tax_regime_key.presence || default_regime_key(tax_year), tax_year)
        calculator = SUPPORTED_METHODS[regime.parameter_text("calculation_method")]

        raise unsupported_regime_error_for(regime) unless calculator

        result = if calculator == SelfEmployedCalculator
          calculator.call(
            gross_income: normalized_gross_income,
            salary_period:,
            tax_regime_key: regime.key,
            tax_year:,
            deductible_expenses: normalized_deductible_expenses,
            children_count: resolved_children_count,
            children_under_three_count: resolved_children_under_three_count,
            disability_level: resolved_disability_level,
            business_activity_type: business_activity_type.presence || "professional_services",
            ascendants_count: resolved_ascendants_count,
            general_family_expenses: resolved_general_family_expenses,
            health_expenses: resolved_health_expenses,
            education_expenses: resolved_education_expenses,
            housing_rent: resolved_housing_rent,
            alimony_paid: resolved_alimony_paid,
            care_home_expenses: resolved_care_home_expenses,
            domestic_work_expenses: resolved_domestic_work_expenses,
            young_dependents_second_later_under_six_count: resolved_young_dependents_second_later_under_six_count,
            vat_invoice_expenses: resolved_vat_invoice_expenses,
            vat_invoice_validation_state: resolved_vat_invoice_validation_state,
            disability_rehabilitation_expenses: resolved_disability_rehabilitation_expenses,
            disability_insurance_premiums: resolved_disability_insurance_premiums,
            ppr_contributions: resolved_ppr_contributions,
            ppr_age_band: resolved_ppr_age_band,
            donations: resolved_donations,
            filing_status: resolved_filing_status,
            apply_irs_jovem:,
            irs_jovem_year: resolved_irs_jovem_year,
            self_employed_tax_regime: self_employed_tax_regime.presence || "simplified",
            start_activity_year: start_activity_year.presence || "none",
            social_security_exemption:,
            social_security_adjustment_mode: social_security_adjustment_mode.presence || "standard"
          )
        else
          calculator.call(
            gross_income: normalized_gross_income,
            salary_period:,
            tax_regime_key: regime.key,
            tax_year:,
            children_count: resolved_children_count,
            children_under_three_count: resolved_children_under_three_count,
            disability_level: resolved_disability_level,
            ascendants_count: resolved_ascendants_count,
            general_family_expenses: resolved_general_family_expenses,
            health_expenses: resolved_health_expenses,
            education_expenses: resolved_education_expenses,
            housing_rent: resolved_housing_rent,
            alimony_paid: resolved_alimony_paid,
            care_home_expenses: resolved_care_home_expenses,
            domestic_work_expenses: resolved_domestic_work_expenses,
            young_dependents_second_later_under_six_count: resolved_young_dependents_second_later_under_six_count,
            vat_invoice_expenses: resolved_vat_invoice_expenses,
            vat_invoice_validation_state: resolved_vat_invoice_validation_state,
            disability_rehabilitation_expenses: resolved_disability_rehabilitation_expenses,
            disability_insurance_premiums: resolved_disability_insurance_premiums,
            ppr_contributions: resolved_ppr_contributions,
            ppr_age_band: resolved_ppr_age_band,
            donations: resolved_donations,
            filing_status: resolved_filing_status,
            apply_irs_jovem:,
            irs_jovem_year: resolved_irs_jovem_year,
            union_dues: resolved_union_dues,
            professional_order_dues: resolved_professional_order_dues
          )
        end

        input_currency_handler.apply_to_result(result, input_currency_code: resolved_input_currency_code)
      end
    end
  end
end
