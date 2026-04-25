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
        domestic_work_expenses: 0
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
            domestic_work_expenses: resolved_domestic_work_expenses
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
            domestic_work_expenses: resolved_domestic_work_expenses
          )
        end

        input_currency_handler.apply_to_result(result, input_currency_code: resolved_input_currency_code)
      end
    end
  end
end
