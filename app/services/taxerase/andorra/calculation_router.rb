module Taxerase
  module Andorra
    class CalculationRouter
      extend Taxerase::Support::CountryRouter

      class UnsupportedRegimeError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      COUNTRY_CODE = "AD".freeze
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
        ascendants_count: 0,
        disabled_dependents_count: 0,
        has_spouse_or_partner: false,
        spouse_without_income: false,
        spouse_general_income: 0,
        mortgage_interest: 0,
        pension_contributions: 0,
        alimony_paid: 0,
        self_employed_social_security_regime: "standard",
        apply_housing_rent_support: false,
        housing_support_priority_group: false,
        housing_rent: 0
      )
        age_bracket
        resolved_input_currency_code = input_currency_handler.resolve_input_currency_code(input_currency_code)
        normalized_gross_income = input_currency_handler.convert_amount(gross_income, input_currency_code: resolved_input_currency_code)
        normalized_deductible_expenses = input_currency_handler.convert_amount(deductible_expenses, input_currency_code: resolved_input_currency_code)
        normalized_spouse_general_income = input_currency_handler.convert_amount(spouse_general_income, input_currency_code: resolved_input_currency_code)
        normalized_mortgage_interest = input_currency_handler.convert_amount(mortgage_interest, input_currency_code: resolved_input_currency_code)
        normalized_pension_contributions = input_currency_handler.convert_amount(pension_contributions, input_currency_code: resolved_input_currency_code)
        normalized_alimony_paid = input_currency_handler.convert_amount(alimony_paid, input_currency_code: resolved_input_currency_code)
        normalized_housing_rent = input_currency_handler.convert_amount(housing_rent, input_currency_code: resolved_input_currency_code)

        regime = lookup_regime(tax_regime_key.presence || default_regime_key(tax_year), tax_year)
        raise UnsupportedRegimeError.new([ "#{tax_regime_key} is not available for Andorra #{tax_year}." ]) if regime.nil?

        calculator = SUPPORTED_METHODS[regime.parameter_text("calculation_method")]
        raise UnsupportedRegimeError.new([ unsupported_message_for(regime) ]) if calculator.nil?

        kwargs = {
          gross_income: normalized_gross_income,
          salary_period: salary_period,
          tax_regime_key: regime.key,
          tax_year: tax_year,
          children_count: children_count.presence || 0,
          children_under_three_count: children_under_three_count.presence || 0,
          disability_level: disability_level.presence || "none",
          ascendants_count: ascendants_count.presence || 0,
          disabled_dependents_count: disabled_dependents_count.presence || 0,
          has_spouse_or_partner: has_spouse_or_partner,
          spouse_without_income: spouse_without_income,
          spouse_general_income: normalized_spouse_general_income,
          mortgage_interest: normalized_mortgage_interest,
          pension_contributions: normalized_pension_contributions,
          alimony_paid: normalized_alimony_paid,
          self_employed_social_security_regime: self_employed_social_security_regime.presence || "standard",
          apply_housing_rent_support: apply_housing_rent_support,
          housing_support_priority_group: housing_support_priority_group,
          housing_rent: normalized_housing_rent
        }
        kwargs[:deductible_expenses] = normalized_deductible_expenses if calculator == SelfEmployedCalculator

        result = calculator.call(**kwargs)
        input_currency_handler.apply_to_result(result, input_currency_code: resolved_input_currency_code)
      end

      def self.supported?(regime_or_key, tax_year = nil)
        regime = regime_or_key.is_a?(TaxRegime) ? regime_or_key : lookup_regime(regime_or_key, tax_year)
        regime.present? && regime.country_id == country.id && SUPPORTED_METHODS.key?(regime.parameter_text("calculation_method"))
      end

      def self.lookup_regime(regime_key, tax_year)
        find_regime(regime_key, tax_year)
      end
    end
  end
end
