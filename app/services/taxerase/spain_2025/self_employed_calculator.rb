module Taxerase
  module Spain2025
    class SelfEmployedCalculator
      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      TAX_YEAR = 2025
      COUNTRY_CODE = "ES".freeze

      def self.call(gross_income:, salary_period:, tax_regime_key:, deductible_expenses:)
        new(gross_income:, salary_period:, tax_regime_key:, deductible_expenses:).call
      end

      def initialize(gross_income:, salary_period:, tax_regime_key:, deductible_expenses:)
        @gross_income = gross_income
        @salary_period = salary_period
        @tax_regime_key = tax_regime_key
        @deductible_expenses = deductible_expenses
      end

      def call
        validate!

        annual_gross_income = normalize_annual_gross_income
        annual_deductible_expenses = parsed_deductible_expenses
        net_income_before_social_security = [ annual_gross_income - annual_deductible_expenses, 0 ].max
        monthly_net_returns_for_social_security = average_monthly_net_returns_for_social_security(net_income_before_social_security)
        social_security_band = social_security_band_for(monthly_net_returns_for_social_security)
        monthly_social_security_base = social_security_band.base_min.to_d
        annual_social_security = monthly_social_security_base * 12 * parameter_decimal!("self_employed_social_security_rate")
        activity_income_before_generic_deduction = [ net_income_before_social_security - annual_social_security, 0 ].max
        difficult_to_justify_deduction = [
          activity_income_before_generic_deduction * parameter_decimal!("difficult_to_justify_deduction_rate"),
          parameter_decimal!("difficult_to_justify_deduction_cap")
        ].min
        taxable_activity_income = [ activity_income_before_generic_deduction - difficult_to_justify_deduction, 0 ].max
        state_brackets = regime.brackets_for("state_irpf")
        regional_brackets = regime.brackets_for("regional_irpf")
        state_tax_before_minimum = ProgressiveTax.call(amount: taxable_activity_income, brackets: state_brackets)
        regional_tax_before_minimum = ProgressiveTax.call(amount: taxable_activity_income, brackets: regional_brackets)
        state_minimum_relief = ProgressiveTax.call(amount: [ taxable_activity_income, parameter_decimal!("state_taxpayer_minimum") ].min, brackets: state_brackets)
        regional_minimum_relief = ProgressiveTax.call(amount: [ taxable_activity_income, parameter_decimal!("regional_taxpayer_minimum") ].min, brackets: regional_brackets)
        annual_income_tax = [
          state_tax_before_minimum + regional_tax_before_minimum - state_minimum_relief - regional_minimum_relief,
          0
        ].max
        total_tax = annual_income_tax + annual_social_security
        annual_net_income = annual_gross_income - annual_deductible_expenses - total_tax

        {
          metadata: metadata,
          input: {
            gross_income: round_currency(parsed_gross_income),
            deductible_expenses: round_currency(annual_deductible_expenses),
            salary_period: normalized_salary_period,
            annual_gross_income: round_currency(annual_gross_income),
            monthly_gross_income: round_currency(annual_gross_income / 12)
          },
          breakdown: {
            annual_deductible_expenses: round_currency(annual_deductible_expenses),
            net_income_before_social_security: round_currency(net_income_before_social_security),
            monthly_net_returns_for_social_security: round_currency(monthly_net_returns_for_social_security),
            monthly_social_security_base: round_currency(monthly_social_security_base),
            annual_social_security: round_currency(annual_social_security),
            difficult_to_justify_deduction: round_currency(difficult_to_justify_deduction),
            taxable_activity_income: round_currency(taxable_activity_income),
            state_tax_before_minimum: round_currency(state_tax_before_minimum),
            regional_tax_before_minimum: round_currency(regional_tax_before_minimum),
            state_minimum_relief: round_currency(state_minimum_relief),
            regional_minimum_relief: round_currency(regional_minimum_relief),
            annual_income_tax: round_currency(annual_income_tax),
            total_tax: round_currency(total_tax),
            annual_net_income: round_currency(annual_net_income),
            monthly_net_income: round_currency(annual_net_income / 12),
            effective_tax_rate: round_percentage(total_tax / annual_gross_income)
          },
          detail_cards: [
            { label: "Deductible expenses", value: round_currency(annual_deductible_expenses) },
            { label: "Net income before social security", value: round_currency(net_income_before_social_security) },
            { label: "Self-employed social security", value: round_currency(annual_social_security) },
            { label: "5% difficult-to-justify deduction", value: round_currency(difficult_to_justify_deduction) },
            { label: "Taxable activity income", value: round_currency(taxable_activity_income) },
            { label: "Income tax", value: round_currency(annual_income_tax) },
            { label: "Total tax", value: round_currency(total_tax) },
            { label: "Estimated monthly RETA base", value: round_currency(monthly_social_security_base) }
          ],
          assumptions: assumptions(social_security_band)
        }
      end

      private

      attr_reader :gross_income, :salary_period, :tax_regime_key, :deductible_expenses

      def validate!
        errors = []
        errors << "gross_income must be a number greater than 0" if parsed_gross_income <= 0
        errors << "gross_income is too large for the current calculator" if parsed_gross_income > 50_000_000
        errors << "deductible_expenses must be 0 or greater" if parsed_deductible_expenses.negative?
        errors << "deductible_expenses is too large for the current calculator" if parsed_deductible_expenses > 50_000_000
        errors << "salary_period must be YEAR or MONTH" unless %w[YEAR MONTH].include?(normalized_salary_period)
        errors << "tax_regime_key must point to a supported self-employed regime" if regime.blank?
        raise ValidationError.new(errors) if errors.any?
      end

      def regime
        @regime ||= TaxRegime.includes(:country, :tax_brackets, :tax_parameters).find_by(
          country:,
          key: tax_regime_key,
          tax_year: TAX_YEAR,
          category: "self_employed"
        )
      end

      def country
        @country ||= Country.find_by!(code: COUNTRY_CODE)
      end

      def metadata
        {
          country_code: regime.country.code,
          country_name: regime.country.name,
          region: regime.region,
          tax_year: regime.tax_year,
          tax_regime_key: regime.key,
          tax_regime_name: regime.name,
          calculator_version: "spain-2025-self-employed-v1"
        }
      end

      def assumptions(social_security_band)
        [
          "Spain, tax year 2025.",
          "Resident self-employed person in #{regime.region} using direct estimation simplified.",
          "Single taxpayer, under 65, no children, no disability, and no extra deductions or credits.",
          "User-entered deductible expenses are treated as ordinary fully deductible business expenses.",
          "The RETA band is estimated from annual revenue minus deductible expenses, less the official 7% generic expense adjustment, converted to average monthly net returns.",
          "The monthly RETA contribution basis is set to the minimum basis of the matching official 2025 band (#{social_security_band.label}).",
          "The 5% difficult-to-justify deduction is applied with the official EUR 2,000 annual cap.",
          "Flat-rate start-up reductions, objective estimation, pluriactivity, family collaborator, and corporate-self-employed variations are not included.",
          "Regional IRPF currently covers the common-regime autonomous communities plus Ceuta and Melilla. Basque Country and Navarre are not included in this slice."
        ]
      end

      def parsed_gross_income
        @parsed_gross_income ||= BigDecimal(gross_income.to_s)
      rescue ArgumentError
        BigDecimal("0")
      end

      def parsed_deductible_expenses
        @parsed_deductible_expenses ||= BigDecimal(deductible_expenses.to_s)
      rescue ArgumentError
        BigDecimal("0")
      end

      def normalized_salary_period
        @normalized_salary_period ||= salary_period.to_s.upcase
      end

      def normalize_annual_gross_income
        normalized_salary_period == "MONTH" ? parsed_gross_income * 12 : parsed_gross_income
      end

      def parameter_decimal!(key)
        regime.parameter_decimal!(key)
      end

      def average_monthly_net_returns_for_social_security(net_income_before_social_security)
        (net_income_before_social_security * (BigDecimal("1") - parameter_decimal!("self_employed_social_security_generic_expense_rate"))) / 12
      end

      def social_security_band_for(monthly_net_returns)
        regime.bracket_for_amount("self_employed_social_security_bands", monthly_net_returns) ||
          regime.bracket_records_for("self_employed_social_security_bands").last ||
          raise(KeyError, "Missing self-employed Social Security bands for #{regime.key}")
      end

      def round_currency(amount)
        amount.round(2).to_f
      end

      def round_percentage(decimal)
        (decimal * 100).round(2).to_f
      end
    end
  end
end
