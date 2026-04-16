module Taxerase
  module Poland
    class CalculationRouter
      class UnsupportedRegimeError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      COUNTRY_CODE = "PL".freeze
      NATIVE_CURRENCY_CODE = "PLN".freeze
      SUPPORTED_INPUT_CURRENCY_CODES = %w[PLN EUR].freeze
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
        age_bracket: "age_26_to_retirement",
        children_count: 0,
        children_under_three_count: 0,
        disability_level: "none",
        apply_return_relief: false,
        apply_family_4plus_relief: false,
        apply_working_senior_relief: false,
        revenue_cost_mode: "normal",
        monthly_tax_relief_mode: "full",
        ppk_employee_rate: 0,
        ppk_employer_rate: 0,
        employer_accident_rate: 1.67,
        include_labor_fund: true,
        include_fgsp: true,
        b2b_tax_form: "tax_scale",
        lump_sum_rate: 12,
        social_insurance_mode: "standard",
        include_sickness_contribution: true,
        business_days_in_month: 30,
        previous_year_average_monthly_income: 12_000
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

        raise UnsupportedRegimeError.new([ unsupported_message_for(regime) ]) unless calculator

        result = if calculator == SelfEmployedCalculator
          calculator.call(
            gross_income: normalized_gross_income,
            salary_period:,
            tax_regime_key: regime.key,
            tax_year:,
            deductible_expenses: value_or_default(normalized_deductible_expenses, 0),
            age_bracket: value_or_default(age_bracket, "age_26_to_retirement"),
            children_count:,
            apply_return_relief: value_or_default(apply_return_relief, false),
            apply_family_4plus_relief: value_or_default(apply_family_4plus_relief, false),
            apply_working_senior_relief: value_or_default(apply_working_senior_relief, false),
            b2b_tax_form: value_or_default(b2b_tax_form, "tax_scale"),
            lump_sum_rate: value_or_default(lump_sum_rate, 12),
            social_insurance_mode: value_or_default(social_insurance_mode, "standard"),
            include_sickness_contribution: value_or_default(include_sickness_contribution, true),
            business_days_in_month: value_or_default(business_days_in_month, 30),
            previous_year_average_monthly_income: value_or_default(previous_year_average_monthly_income, 12_000)
          )
        else
          calculator.call(
            gross_income: normalized_gross_income,
            salary_period:,
            tax_regime_key: regime.key,
            tax_year:,
            age_bracket: value_or_default(age_bracket, "age_26_to_retirement"),
            children_count:,
            apply_return_relief: value_or_default(apply_return_relief, false),
            apply_family_4plus_relief: value_or_default(apply_family_4plus_relief, false),
            apply_working_senior_relief: value_or_default(apply_working_senior_relief, false),
            revenue_cost_mode: value_or_default(revenue_cost_mode, "normal"),
            monthly_tax_relief_mode: value_or_default(monthly_tax_relief_mode, "full"),
            ppk_employee_rate: value_or_default(ppk_employee_rate, 0),
            ppk_employer_rate: value_or_default(ppk_employer_rate, 0),
            employer_accident_rate: value_or_default(employer_accident_rate, 1.67),
            include_labor_fund: value_or_default(include_labor_fund, true),
            include_fgsp: value_or_default(include_fgsp, true)
          )
        end

        input_currency_handler.apply_to_result(result, input_currency_code: resolved_input_currency_code)
      end

      def self.default_regime_key(tax_year)
        TaxRegime.default_supported_key_for(
          country:,
          tax_year:,
          supported_methods: SUPPORTED_METHODS.keys
        )
      end

      def self.regime_options(catalog_options = nil)
        return TaxRegime.public_regime_options_for(country:, catalog_options:) if catalog_options

        TaxRegime
          .for_country(country)
          .includes(:tax_parameters, tax_source_usages: :official_tax_source)
          .ordered_for_catalog
          .map do |regime|
            supported = supported?(regime)
            {
              key: regime.key,
              name: regime.name,
              region: regime.region,
              category: regime.category,
              tax_year: regime.tax_year,
              description: regime.description,
              supported:,
              status: supported ? "Live" : "Research",
              sources: regime.source_links
            }
          end
      end

      def self.public_regime_options(catalog_options = nil)
        regime_options(catalog_options || public_catalog_regime_options)
      end

      def self.public_catalog_regime_options
        TaxRegime.public_catalog_options_for(country:, supported_methods: SUPPORTED_METHODS.keys)
      end

      def self.public_catalog_data
        TaxRegime.public_catalog_data_for(country:, supported_methods: SUPPORTED_METHODS.keys)
      end

      def self.public_regime_categories
        TaxRegime.supported_categories_for(country:, supported_methods: SUPPORTED_METHODS.keys)
      end

      def self.public_tax_year_options
        TaxRegime.supported_tax_years_for(country:, supported_methods: SUPPORTED_METHODS.keys)
      end

      def self.supported?(regime_or_key, tax_year = nil)
        regime = if regime_or_key.is_a?(TaxRegime)
          regime_or_key
        else
          TaxRegime.for_country_year(country:, tax_year:).find_by(key: regime_or_key)
        end

        regime.present? && regime.country_id == country.id && SUPPORTED_METHODS.key?(regime.parameter_text("calculation_method"))
      end

      def self.regime_for!(regime_key, tax_year)
        TaxRegime
          .with_routing_data
          .for_country_year(country:, tax_year:)
          .find_by!(key: regime_key)
      rescue ActiveRecord::RecordNotFound
        raise UnsupportedRegimeError.new([ "#{regime_key} is not available for Poland #{tax_year}." ])
      end

      def self.unsupported_message_for(regime)
        "#{regime.name} is stored in the rules database, but its calculator flow is not implemented yet."
      end

      def self.country
        @country ||= Country.find_by!(code: COUNTRY_CODE)
      end

      def self.input_currency_handler
        @input_currency_handler ||= Taxerase::InputCurrencyHandler.new(
          native_currency_code: NATIVE_CURRENCY_CODE,
          supported_currency_codes: SUPPORTED_INPUT_CURRENCY_CODES
        )
      end

      def self.value_or_default(value, default)
        value.nil? ? default : value
      end
    end
  end
end
