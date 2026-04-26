module Taxerase
  module CzechRepublic
    class CalculationRouter
      extend Taxerase::Support::CountryRouter

      class UnsupportedRegimeError < Taxerase::UnsupportedRegimeError; end

      COUNTRY_CODE = "CZ".freeze
      NATIVE_CURRENCY_CODE = "CZK".freeze
      SUPPORTED_INPUT_CURRENCY_CODES = %w[CZK EUR].freeze
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
        expense_deduction_method: "actual_expenses",
        age_bracket: "standard",
        children_count: 0,
        children_under_three_count: 0,
        disability_level: "none",
        child_credit_claim_share: 100,
        apply_spouse_credit: false,
        spouse_income: 0,
        spouse_ztp_p: false,
        spouse_cares_child_under_three: false,
        mortgage_interest_paid: 0,
        pension_contributions: 0,
        life_insurance_contributions: 0,
        donations_amount: 0,
        self_employed_tax_mode: "standard",
        osvc_activity_status: "main"
      )
        resolved_input_currency_code = input_currency_handler.resolve_input_currency_code(input_currency_code)
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
            expense_deduction_method: expense_deduction_method.presence || "actual_expenses",
            children_count:,
            disability_level:,
            child_credit_claim_share: value_or_default(child_credit_claim_share, 100),
            apply_spouse_credit: value_or_default(apply_spouse_credit, false),
            spouse_income: value_or_default(spouse_income, 0),
            spouse_ztp_p: value_or_default(spouse_ztp_p, false),
            spouse_cares_child_under_three: value_or_default(spouse_cares_child_under_three, false),
            mortgage_interest_paid: value_or_default(mortgage_interest_paid, 0),
            pension_contributions: value_or_default(pension_contributions, 0),
            life_insurance_contributions: value_or_default(life_insurance_contributions, 0),
            donations_amount: value_or_default(donations_amount, 0),
            self_employed_tax_mode: value_or_default(self_employed_tax_mode, "standard"),
            osvc_activity_status: value_or_default(osvc_activity_status, "main")
          )
        else
          calculator.call(
            gross_income: normalized_gross_income,
            salary_period:,
            tax_regime_key: regime.key,
            tax_year:,
            children_count:,
            disability_level:,
            child_credit_claim_share: value_or_default(child_credit_claim_share, 100),
            apply_spouse_credit: value_or_default(apply_spouse_credit, false),
            spouse_income: value_or_default(spouse_income, 0),
            spouse_ztp_p: value_or_default(spouse_ztp_p, false),
            spouse_cares_child_under_three: value_or_default(spouse_cares_child_under_three, false),
            mortgage_interest_paid: value_or_default(mortgage_interest_paid, 0),
            pension_contributions: value_or_default(pension_contributions, 0),
            life_insurance_contributions: value_or_default(life_insurance_contributions, 0),
            donations_amount: value_or_default(donations_amount, 0)
          )
        end

        input_currency_handler.apply_to_result(result, input_currency_code: resolved_input_currency_code)
      end

      def self.country_name_in_errors
        "the Czech Republic"
      end

      def self.value_or_default(value, default)
        value.nil? ? default : value
      end
    end
  end
end
