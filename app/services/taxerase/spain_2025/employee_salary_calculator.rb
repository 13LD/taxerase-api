module Taxerase
  module Spain2025
    class EmployeeSalaryCalculator
      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      TAX_YEAR = 2025
      COUNTRY_CODE = "ES".freeze

      def self.call(gross_income:, salary_period:, tax_regime_key:)
        new(gross_income:, salary_period:, tax_regime_key:).call
      end

      def initialize(gross_income:, salary_period:, tax_regime_key:)
        @gross_income = gross_income
        @salary_period = salary_period
        @tax_regime_key = tax_regime_key
      end

      def call
        validate!

        annual_gross_income = normalize_annual_gross_income
        monthly_gross_income = annual_gross_income / 12
        contribution_base_monthly = monthly_contribution_base_for(monthly_gross_income)
        annual_social_security = contribution_base_monthly * 12 * parameter_decimal!("employee_social_security_rate")
        taxable_work_income = [ annual_gross_income - annual_social_security - parameter_decimal!("gross_work_income_deduction"), 0 ].max
        state_brackets = regime.brackets_for("state_irpf")
        regional_brackets = regime.brackets_for("regional_irpf")
        state_tax_before_minimum = ProgressiveTax.call(amount: taxable_work_income, brackets: state_brackets)
        regional_tax_before_minimum = ProgressiveTax.call(amount: taxable_work_income, brackets: regional_brackets)
        state_minimum_relief = ProgressiveTax.call(amount: [ taxable_work_income, parameter_decimal!("state_taxpayer_minimum") ].min, brackets: state_brackets)
        regional_minimum_relief = ProgressiveTax.call(amount: [ taxable_work_income, parameter_decimal!("regional_taxpayer_minimum") ].min, brackets: regional_brackets)
        work_income_deduction = low_income_deduction_for(annual_gross_income)
        annual_income_tax = [
          state_tax_before_minimum + regional_tax_before_minimum - state_minimum_relief - regional_minimum_relief - work_income_deduction,
          0
        ].max
        total_tax = annual_income_tax + annual_social_security
        annual_net_income = annual_gross_income - total_tax

        {
          metadata: metadata,
          input: {
            gross_income: round_currency(parsed_gross_income),
            salary_period: normalized_salary_period,
            annual_gross_income: round_currency(annual_gross_income),
            monthly_gross_income: round_currency(monthly_gross_income)
          },
          breakdown: {
            annual_social_security: round_currency(annual_social_security),
            taxable_work_income: round_currency(taxable_work_income),
            state_tax_before_minimum: round_currency(state_tax_before_minimum),
            regional_tax_before_minimum: round_currency(regional_tax_before_minimum),
            state_minimum_relief: round_currency(state_minimum_relief),
            regional_minimum_relief: round_currency(regional_minimum_relief),
            work_income_deduction: round_currency(work_income_deduction),
            annual_income_tax: round_currency(annual_income_tax),
            total_tax: round_currency(total_tax),
            annual_net_income: round_currency(annual_net_income),
            monthly_net_income: round_currency(annual_net_income / 12),
            effective_tax_rate: round_percentage(total_tax / annual_gross_income)
          },
          detail_cards: [
            { label: "Income tax", value: round_currency(annual_income_tax) },
            { label: "Employee social security", value: round_currency(annual_social_security) },
            { label: "Total tax", value: round_currency(total_tax) },
            { label: "Taxable work income", value: round_currency(taxable_work_income) },
            { label: "State minimum relief", value: round_currency(state_minimum_relief) },
            { label: "#{regime.region} minimum relief", value: round_currency(regional_minimum_relief) }
          ],
          assumptions: assumptions
        }
      end

      private

      attr_reader :gross_income, :salary_period, :tax_regime_key

      def validate!
        errors = []
        errors << "gross_income must be a number greater than 0" if parsed_gross_income <= 0
        errors << "gross_income is too large for the current calculator" if parsed_gross_income > 50_000_000
        errors << "salary_period must be YEAR or MONTH" unless %w[YEAR MONTH].include?(normalized_salary_period)
        errors << "tax_regime_key must point to a supported employee regime" if regime.blank?
        raise ValidationError.new(errors) if errors.any?
      end

      def regime
        @regime ||= TaxRegime.includes(:country, :tax_brackets, :tax_parameters).find_by(
          country:,
          key: tax_regime_key,
          tax_year: TAX_YEAR,
          category: "employee"
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
          calculator_version: "spain-2025-employee-v2"
        }
      end

      def assumptions
        [
          "Spain only, tax year 2025.",
          "Resident salaried employee in #{regime.region} under the common IRPF regime.",
          "Single taxpayer, under 65, no children, no disability, no union dues, and no extra deductions or credits.",
          "Standard indefinite contract assumptions for employee Social Security.",
          "Employee Social Security uses the 2025 worker rates for common contingencies, unemployment, training, and MEI, capped by the official monthly bases.",
          "General deductible employee work expense of EUR 2,000 is applied.",
          "The 2025 work-income deduction is only applied when salary falls below the official threshold.",
          "Regional IRPF currently covers the common-regime autonomous communities plus Ceuta and Melilla. Basque Country and Navarre are not included in this slice."
        ]
      end

      def parsed_gross_income
        @parsed_gross_income ||= BigDecimal(gross_income.to_s)
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

      def monthly_contribution_base_for(monthly_gross_income)
        return BigDecimal("0") if monthly_gross_income <= 0

        min_base = parameter_decimal!("monthly_min_contribution_base")
        max_base = parameter_decimal!("monthly_max_contribution_base")

        [ [ monthly_gross_income, max_base ].min, min_base ].max
      end

      def low_income_deduction_for(annual_gross_income)
        max_deduction = parameter_decimal!("low_income_deduction_max")
        full_threshold = parameter_decimal!("low_income_deduction_full_threshold")
        phase_out_threshold = parameter_decimal!("low_income_deduction_phase_out_threshold")
        phase_out_rate = parameter_decimal!("low_income_deduction_phase_out_rate")

        return BigDecimal("0") if annual_gross_income >= phase_out_threshold
        return max_deduction if annual_gross_income <= full_threshold

        max_deduction - (annual_gross_income - full_threshold) * phase_out_rate
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
