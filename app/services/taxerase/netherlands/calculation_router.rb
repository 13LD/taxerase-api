module Taxerase
  module Netherlands
    class CalculationRouter
      extend Taxerase::Support::CountryRouter

      class UnsupportedRegimeError < Taxerase::UnsupportedRegimeError; end

      COUNTRY_CODE = "NL".freeze
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
        age_bracket: "under_aow_age",
        apply_thirty_percent_ruling: false,
        thirty_percent_ruling_basis: nil,
        children_count: 0,
        children_under_three_count: 0,
        disability_level: "none"
      )
        resolved_input_currency_code = input_currency_handler.resolve_input_currency_code(input_currency_code)
        regime = regime_for!(tax_regime_key.presence || default_regime_key(tax_year), tax_year)
        calculator = SUPPORTED_METHODS[regime.parameter_text("calculation_method")]

        raise unsupported_regime_error_for(regime) unless calculator

        result = if calculator == SelfEmployedCalculator
          calculator.call(
            gross_income:,
            salary_period:,
            tax_regime_key: regime.key,
            tax_year:,
            deductible_expenses:,
            age_bracket:
          )
        else
          calculator.call(
            gross_income:,
            salary_period:,
            tax_regime_key: regime.key,
            tax_year:,
            age_bracket:,
            apply_thirty_percent_ruling:,
            thirty_percent_ruling_basis:
          )
        end

        input_currency_handler.apply_to_result(result, input_currency_code: resolved_input_currency_code)
      end

      def self.country_name_in_errors
        "the Netherlands"
      end

      def self.source_backed_unsupported_message?
        true
      end
    end
  end
end
