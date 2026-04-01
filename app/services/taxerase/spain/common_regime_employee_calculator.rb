module Taxerase
  module Spain
    class CommonRegimeEmployeeCalculator
      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      CALCULATION_METHOD = "common_regime_employee_v1".freeze
      COUNTRY_CODE = "ES".freeze

      def self.call(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        age_bracket:,
        children_count:,
        children_under_three_count:,
        disability_level:
      )
        new(
          gross_income:,
          salary_period:,
          tax_regime_key:,
          tax_year:,
          age_bracket:,
          children_count:,
          children_under_three_count:,
          disability_level:
        ).call
      end

      def initialize(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        age_bracket:,
        children_count:,
        children_under_three_count:,
        disability_level:
      )
        @gross_income = gross_income
        @salary_period = salary_period
        @tax_regime_key = tax_regime_key
        @tax_year = tax_year
        @age_bracket = age_bracket
        @children_count = children_count
        @children_under_three_count = children_under_three_count
        @disability_level = disability_level
      end

      def call
        validate!

        annual_gross_income = normalize_annual_gross_income
        monthly_gross_income = annual_gross_income / 12
        contribution_base_monthly = monthly_contribution_base_for(monthly_gross_income)
        annual_social_security = contribution_base_monthly * 12 * parameter_decimal!("employee_social_security_rate")
        net_work_income_before_adjustment = [
          annual_gross_income - annual_social_security - parameter_decimal!("gross_work_income_deduction"),
          0
        ].max
        work_income_adjustment = work_income_adjustment_for(
          annual_gross_income: annual_gross_income,
          net_work_income_before_adjustment: net_work_income_before_adjustment
        )
        taxable_work_income = taxable_work_income_for(
          net_work_income_before_adjustment: net_work_income_before_adjustment,
          work_income_adjustment: work_income_adjustment
        )
        personal_family_minimums = personal_family_minimums_data
        state_brackets = regime.brackets_for("state_irpf")
        regional_brackets = regime.brackets_for("regional_irpf")
        state_tax_before_minimum = ProgressiveTax.call(amount: taxable_work_income, brackets: state_brackets)
        regional_tax_before_minimum = ProgressiveTax.call(amount: taxable_work_income, brackets: regional_brackets)
        state_minimum_relief = ProgressiveTax.call(
          amount: [ taxable_work_income, personal_family_minimums[:state_amount] ].min,
          brackets: state_brackets
        )
        regional_minimum_relief = ProgressiveTax.call(
          amount: [ taxable_work_income, personal_family_minimums[:regional_amount] ].min,
          brackets: regional_brackets
        )
        annual_income_tax_before_work_income_adjustment = [
          state_tax_before_minimum + regional_tax_before_minimum - state_minimum_relief - regional_minimum_relief,
          0
        ].max
        annual_income_tax = [
          annual_income_tax_before_work_income_adjustment - work_income_tax_credit_amount(work_income_adjustment),
          0
        ].max
        total_tax = annual_income_tax + annual_social_security
        annual_net_income = annual_gross_income - total_tax

        {
          metadata: metadata,
          input: {
            gross_income: round_currency(parsed_gross_income),
            salary_period: normalized_salary_period,
            tax_year: tax_year,
            annual_gross_income: round_currency(annual_gross_income),
            monthly_gross_income: round_currency(monthly_gross_income),
            age_bracket: age_bracket,
            children_count: parsed_children_count,
            children_under_three_count: parsed_children_under_three_count,
            disability_level: disability_level
          },
          breakdown: {
            annual_social_security: round_currency(annual_social_security),
            net_work_income_before_adjustment: round_currency(net_work_income_before_adjustment),
            taxable_work_income: round_currency(taxable_work_income),
            state_tax_before_minimum: round_currency(state_tax_before_minimum),
            regional_tax_before_minimum: round_currency(regional_tax_before_minimum),
            state_personal_and_family_minimum: round_currency(personal_family_minimums[:state_amount]),
            regional_personal_and_family_minimum: round_currency(personal_family_minimums[:regional_amount]),
            state_minimum_relief: round_currency(state_minimum_relief),
            regional_minimum_relief: round_currency(regional_minimum_relief),
            work_income_adjustment: round_currency(work_income_adjustment),
            annual_income_tax_before_work_income_adjustment: round_currency(annual_income_tax_before_work_income_adjustment),
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
            { label: "State personal and family minimum", value: round_currency(personal_family_minimums[:state_amount]) },
            { label: "#{regime.region} personal and family minimum", value: round_currency(personal_family_minimums[:regional_amount]) },
            { label: "State minimum relief", value: round_currency(state_minimum_relief) },
            { label: "#{regime.region} minimum relief", value: round_currency(regional_minimum_relief) }
          ],
          assumptions: assumptions,
          sources: regime.source_links
        }
      end

      private

      attr_reader :gross_income, :salary_period, :tax_regime_key, :tax_year, :age_bracket, :children_count, :children_under_three_count, :disability_level

      def validate!
        errors = []
        errors << "gross_income must be a number greater than 0" if parsed_gross_income <= 0
        errors << "gross_income is too large for the current calculator" if parsed_gross_income > 2_000_000
        errors << "salary_period must be YEAR or MONTH" unless %w[YEAR MONTH].include?(normalized_salary_period)
        errors << "tax_regime_key must point to a supported employee regime" if regime.blank?
        errors.concat(
          PersonalFamilyMinimums.validation_errors(
            age_bracket:,
            children_count:,
            children_under_three_count:,
            disability_level:
          )
        )
        raise ValidationError.new(errors) if errors.any?
      end

      def regime
        @regime ||= TaxRegime.includes(:country, :tax_brackets, :tax_parameters, tax_source_usages: :official_tax_source).find_by(
          country:,
          key: tax_regime_key,
          tax_year: tax_year,
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
          calculator_version: "spain-common-employee-v1"
        }
      end

      def assumptions
        base_assumptions = [
          "Spain only, tax year #{tax_year}.",
          "Resident salaried employee in #{regime.region} under the common IRPF regime.",
          "Profile inputs: #{personal_family_minimums_data[:summary]}. No union dues, ascendants, joint filing, or other deductions and credits are included.",
          "Standard indefinite contract assumptions for employee Social Security.",
          "Employee Social Security uses the official worker rates and bases stored for the selected year.",
          "Regional IRPF currently covers the common-regime autonomous communities plus Ceuta and Melilla.",
          "Age, children, and taxpayer-disability inputs are applied through the official common personal-and-family minimum structure, using the region-specific taxpayer base minimum already stored for the selected jurisdiction."
        ]

        case work_income_adjustment_mode
        when "net_income_reduction_2024"
          base_assumptions << "The 2024 employee reduction is applied to net work income before IRPF, using the official three-band formula."
        when "tax_credit_2025"
          base_assumptions << "The 2025 employee work-income adjustment is applied as the official low-income tax deduction."
        end

        base_assumptions
      end

      def parsed_gross_income
        @parsed_gross_income ||= BigDecimal(gross_income.to_s)
      rescue ArgumentError
        BigDecimal("0")
      end

      def parsed_children_count
        @parsed_children_count ||= PersonalFamilyMinimums.call(
          regime:,
          age_bracket:,
          children_count:,
          children_under_three_count:,
          disability_level:
        )[:children_count]
      end

      def parsed_children_under_three_count
        @parsed_children_under_three_count ||= PersonalFamilyMinimums.call(
          regime:,
          age_bracket:,
          children_count:,
          children_under_three_count:,
          disability_level:
        )[:children_under_three_count]
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

      def work_income_adjustment_mode
        @work_income_adjustment_mode ||= regime.parameter_text!("work_income_adjustment_mode")
      end

      def work_income_adjustment_for(annual_gross_income:, net_work_income_before_adjustment:)
        case work_income_adjustment_mode
        when "tax_credit_2025"
          low_income_deduction_for(annual_gross_income)
        when "net_income_reduction_2024"
          work_income_reduction_2024_for(net_work_income_before_adjustment)
        else
          raise KeyError, "Unsupported work income adjustment mode #{work_income_adjustment_mode} for #{regime.key}"
        end
      end

      def taxable_work_income_for(net_work_income_before_adjustment:, work_income_adjustment:)
        case work_income_adjustment_mode
        when "tax_credit_2025"
          net_work_income_before_adjustment
        when "net_income_reduction_2024"
          [ net_work_income_before_adjustment - work_income_adjustment, 0 ].max
        else
          raise KeyError, "Unsupported work income adjustment mode #{work_income_adjustment_mode} for #{regime.key}"
        end
      end

      def work_income_tax_credit_amount(work_income_adjustment)
        work_income_adjustment_mode == "tax_credit_2025" ? work_income_adjustment : BigDecimal("0")
      end

      def work_income_reduction_2024_for(net_work_income_before_adjustment)
        max_reduction = parameter_decimal!("work_income_reduction_max")
        full_threshold = parameter_decimal!("work_income_reduction_full_threshold")
        first_phase_threshold = parameter_decimal!("work_income_reduction_first_phase_threshold")
        phase_out_threshold = parameter_decimal!("work_income_reduction_phase_out_threshold")
        first_phase_rate = parameter_decimal!("work_income_reduction_first_phase_rate")
        second_phase_base = parameter_decimal!("work_income_reduction_second_phase_base")
        second_phase_rate = parameter_decimal!("work_income_reduction_second_phase_rate")

        reduction =
          if net_work_income_before_adjustment >= phase_out_threshold
            BigDecimal("0")
          elsif net_work_income_before_adjustment <= full_threshold
            max_reduction
          elsif net_work_income_before_adjustment <= first_phase_threshold
            max_reduction - (net_work_income_before_adjustment - full_threshold) * first_phase_rate
          else
            second_phase_base - (net_work_income_before_adjustment - first_phase_threshold) * second_phase_rate
          end

        [ [ reduction, net_work_income_before_adjustment ].min, 0 ].max
      end

      def round_currency(amount)
        amount.round(2).to_f
      end

      def round_percentage(decimal)
        (decimal * 100).round(2).to_f
      end

      def personal_family_minimums_data
        @personal_family_minimums_data ||= PersonalFamilyMinimums.call(
          regime:,
          age_bracket:,
          children_count:,
          children_under_three_count:,
          disability_level:
        )
      end
    end
  end
end
