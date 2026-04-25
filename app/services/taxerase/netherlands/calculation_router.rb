module Taxerase
  module Netherlands
    class CalculationRouter
      extend Taxerase::Support::CountryRouter

      class UnsupportedRegimeError < Taxerase::UnsupportedRegimeError; end
      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      COUNTRY_CODE = "NL".freeze
      NATIVE_CURRENCY_CODE = "EUR".freeze
      SUPPORTED_INPUT_CURRENCY_CODES = %w[EUR].freeze
      ADVANCED_RULE_TAX_YEAR = 2025

      SUPPORTED_METHODS = {
        EmployeeCalculator::CALCULATION_METHOD => EmployeeCalculator,
        SelfEmployedCalculator::CALCULATION_METHOD => SelfEmployedCalculator
      }.freeze

      CREDIT_AND_DEDUCTION_INPUT_KEYS = %i[
        children_count
        children_under_three_count
        children_under_12_count
        disability_level
        fiscal_partner
        partner_labour_income
        single_aow_household
        wajong_status
        green_investments_value
        partner_alimony_paid
        healthcare_medicines_prescription
        healthcare_aids_and_adaptations
        healthcare_transport
        healthcare_diet_prescribed
        healthcare_extra_family_help
        healthcare_extra_clothing_bedding
        healthcare_other_eligible
        temporary_home_stay_disabled_days
        temporary_home_stay_disabled_km
        ordinary_anbi_gifts
        periodic_anbi_gifts
        cultural_anbi_gifts
        deductible_aov_premium
        deductible_lijfrente_premium
        remaining_personal_deduction_carryforward
      ].freeze

      ENTREPRENEUR_INPUT_KEYS = %i[
        qualifies_as_entrepreneur
        hours_worked_in_business
        has_other_work_hours_higher_than_business
        startup_uses_in_last_5_years
        disabled_starter_scheme
        disabled_starter_deduction_uses
        has_s_and_o_declaration
        s_and_o_hours
        s_and_o_starter
        partner_unpaid_hours
        partner_fee_paid
        business_ceased
        cessation_profit
        stakingsaftrek_used_before
        private_vehicle_business_km
        limited_deductible_costs_amount
        choose_80_percent_method
        kia_basis
        home_workspace_independent
        home_workspace_costs
        cessation_annuity_premium
      ].freeze
      LEGACY_INPUT_KEYS = %i[children_count children_under_three_count disability_level].freeze
      ADVANCED_INPUT_DEFAULTS = {
        qualifies_as_entrepreneur: true,
        hours_worked_in_business: 1225,
        startup_uses_in_last_5_years: 3
      }.freeze
      ADVANCED_INPUT_KEYS = (
        CREDIT_AND_DEDUCTION_INPUT_KEYS + ENTREPRENEUR_INPUT_KEYS - LEGACY_INPUT_KEYS
      ).freeze

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
        disability_level: "none",
        **calculation_inputs
      )
        resolved_input_currency_code = input_currency_handler.resolve_input_currency_code(input_currency_code)
        regime = regime_for!(tax_regime_key.presence || default_regime_key(tax_year), tax_year)
        calculator = SUPPORTED_METHODS[regime.parameter_text("calculation_method")]
        shared_inputs = calculation_inputs.merge(
          children_count:,
          children_under_three_count:,
          disability_level:
        )

        raise unsupported_regime_error_for(regime) unless calculator
        validate_advanced_inputs!(tax_year, calculation_inputs)

        result = if calculator == SelfEmployedCalculator
          calculator.call(
            gross_income:,
            salary_period:,
            tax_regime_key: regime.key,
            tax_year:,
            deductible_expenses:,
            age_bracket:,
            **shared_inputs.slice(*CREDIT_AND_DEDUCTION_INPUT_KEYS, *ENTREPRENEUR_INPUT_KEYS)
          )
        else
          calculator.call(
            gross_income:,
            salary_period:,
            tax_regime_key: regime.key,
            tax_year:,
            age_bracket:,
            apply_thirty_percent_ruling:,
            thirty_percent_ruling_basis:,
            **shared_inputs.slice(*CREDIT_AND_DEDUCTION_INPUT_KEYS)
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

      def self.validate_advanced_inputs!(tax_year, calculation_inputs)
        return if tax_year == ADVANCED_RULE_TAX_YEAR

        unsupported_inputs = ADVANCED_INPUT_KEYS.select do |key|
          calculation_inputs.key?(key) && advanced_input_has_effect?(key, calculation_inputs[key])
        end
        return if unsupported_inputs.empty?

        raise ValidationError.new([
          "Netherlands credit, personal deduction, and entrepreneur detail inputs are currently supported only for tax year #{ADVANCED_RULE_TAX_YEAR}"
        ])
      end

      def self.advanced_input_has_effect?(key, value)
        return true if value.blank?

        default = ADVANCED_INPUT_DEFAULTS.fetch(key, false)
        if [ true, false ].include?(default)
          ActiveModel::Type::Boolean.new.cast(value) != default
        else
          BigDecimal(value.to_s) != BigDecimal(default.to_s)
        end
      rescue ArgumentError
        true
      end
    end
  end
end
