module Taxerase
  module Spain
    class CalculationRouter
      extend Taxerase::Support::CountryRouter

      class UnsupportedRegimeError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      SUPPORTED_METHODS = {
        CommonRegimeEmployeeCalculator::CALCULATION_METHOD => CommonRegimeEmployeeCalculator,
        CommonRegimeSelfEmployedCalculator::CALCULATION_METHOD => CommonRegimeSelfEmployedCalculator,
        BeckhamLawCalculator::CALCULATION_METHOD => BeckhamLawCalculator
      }.freeze
      COUNTRY_CODE = "ES".freeze
      NATIVE_CURRENCY_CODE = "EUR".freeze
      SUPPORTED_INPUT_CURRENCY_CODES = %w[EUR].freeze

      def self.call(
        gross_income:,
        salary_period:,
        tax_year:,
        tax_regime_key: nil,
        input_currency_code: NATIVE_CURRENCY_CODE,
        deductible_expenses: 0,
        apply_beckham_law: false,
        age_bracket: "under_65",
        children_count: 0,
        children_under_three_count: 0,
        disability_level: "none"
      )
        age_bracket = age_bracket.presence || "under_65"
        children_count = children_count.nil? ? 0 : children_count
        children_under_three_count = children_under_three_count.nil? ? 0 : children_under_three_count
        disability_level = disability_level.presence || "none"
        resolved_input_currency_code = input_currency_handler.resolve_input_currency_code(input_currency_code)
        regime = regime_for!(tax_regime_key.presence || default_regime_key(tax_year), tax_year)
        calculator = SUPPORTED_METHODS[regime.parameter_text("calculation_method")]

        raise UnsupportedRegimeError.new([ unsupported_message_for(regime) ]) unless calculator

        result = if calculator == CommonRegimeSelfEmployedCalculator
          calculator.call(
            gross_income:,
            salary_period:,
            tax_regime_key: regime.key,
            tax_year:,
            deductible_expenses:,
            age_bracket:,
            children_count:,
            children_under_three_count:,
            disability_level:
          )
        else
          calculator.call(
            gross_income:,
            salary_period:,
            tax_regime_key: regime.key,
            tax_year:,
            age_bracket:,
            children_count:,
            children_under_three_count:,
            disability_level:
          )
        end

        input_currency_handler.apply_to_result(result, input_currency_code: resolved_input_currency_code)
      end

      def self.source_backed_unsupported_message?
        true
      end
    end
  end
end
