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

      REGIME_KEY = "resident_employee_madrid".freeze
      TAX_YEAR = 2025

      def self.assumptions
        [
          "Spain only, tax year 2025.",
          "Resident employee in the Community of Madrid.",
          "Single taxpayer, under 65, no children, no disability, no union dues, and no extra deductions or credits.",
          "Standard indefinite contract assumptions for employee Social Security.",
          "Employee Social Security modeled with the 2025 worker rates for common contingencies, unemployment, training, and MEI.",
          "General work expense deduction of EUR 2,000 is applied.",
          "The new 2025 work-income deduction is applied only when salary falls below the official threshold.",
          "Solidarity contributions above the maximum contribution base and special regimes such as Beckham Law are researched but not included in this v1 calculator."
        ]
      end

      def self.call(gross_income:, salary_period:)
        new(gross_income:, salary_period:).call
      end

      def initialize(gross_income:, salary_period:)
        @gross_income = gross_income
        @salary_period = salary_period
      end

      def call
        validate!

        regime = employee_regime
        annual_gross_income = normalize_annual_gross_income
        monthly_gross_income = annual_gross_income / 12
        contribution_base_monthly = monthly_contribution_base_for(monthly_gross_income)
        annual_social_security = contribution_base_monthly * 12 * parameter_decimal!("employee_social_security_rate")
        taxable_work_income = [annual_gross_income - annual_social_security - parameter_decimal!("gross_work_income_deduction"), 0].max

        state_brackets = regime.brackets_for("state_irpf")
        regional_brackets = regime.brackets_for("regional_irpf")
        state_tax_before_minimum = ProgressiveTax.call(amount: taxable_work_income, brackets: state_brackets)
        madrid_tax_before_minimum = ProgressiveTax.call(amount: taxable_work_income, brackets: regional_brackets)
        state_minimum_relief = ProgressiveTax.call(amount: [taxable_work_income, parameter_decimal!("state_taxpayer_minimum")].min, brackets: state_brackets)
        madrid_minimum_relief = ProgressiveTax.call(amount: [taxable_work_income, parameter_decimal!("regional_taxpayer_minimum")].min, brackets: regional_brackets)
        work_income_deduction = low_income_deduction_for(annual_gross_income)

        annual_income_tax = [
          state_tax_before_minimum + madrid_tax_before_minimum - state_minimum_relief - madrid_minimum_relief - work_income_deduction,
          0
        ].max

        total_tax = annual_income_tax + annual_social_security
        annual_net_income = annual_gross_income - total_tax

        {
          metadata: {
            country_code: regime.country.code,
            country_name: regime.country.name,
            region: regime.region,
            tax_year: regime.tax_year,
            tax_regime_key: regime.key,
            tax_regime_name: regime.name,
            calculator_version: "spain-2025-employee-v1"
          },
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
            madrid_tax_before_minimum: round_currency(madrid_tax_before_minimum),
            state_minimum_relief: round_currency(state_minimum_relief),
            madrid_minimum_relief: round_currency(madrid_minimum_relief),
            work_income_deduction: round_currency(work_income_deduction),
            annual_income_tax: round_currency(annual_income_tax),
            total_tax: round_currency(total_tax),
            annual_net_income: round_currency(annual_net_income),
            monthly_net_income: round_currency(annual_net_income / 12),
            effective_tax_rate: round_percentage(total_tax / annual_gross_income)
          },
          assumptions: self.class.assumptions
        }
      end

      private

      attr_reader :gross_income, :salary_period

      def validate!
        errors = []
        errors << "gross_income must be a number greater than 0" if parsed_gross_income <= 0
        errors << "gross_income is too large for the current calculator" if parsed_gross_income > 2_000_000
        errors << "salary_period must be YEAR or MONTH" unless %w[YEAR MONTH].include?(normalized_salary_period)
        raise ValidationError.new(errors) if errors.any?
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

      def employee_regime
        @employee_regime ||= TaxRegime.includes(:country, :tax_brackets, :tax_parameters).find_by!(
          key: REGIME_KEY,
          tax_year: TAX_YEAR
        )
      end

      def parameter_decimal!(key)
        employee_regime.parameter_decimal!(key)
      end

      def monthly_contribution_base_for(monthly_gross_income)
        return BigDecimal("0") if monthly_gross_income <= 0

        min_base = parameter_decimal!("monthly_min_contribution_base")
        max_base = parameter_decimal!("monthly_max_contribution_base")

        [[monthly_gross_income, max_base].min, min_base].max
      end
    end
  end
end
