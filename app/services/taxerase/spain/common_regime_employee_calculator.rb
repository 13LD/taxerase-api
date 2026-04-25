module Taxerase
  module Spain
    class CommonRegimeEmployeeCalculator
      include Taxerase::Support::RegimeBackedCalculation
      include InputNormalization

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
        disability_level:,
        ascendants_count: 0,
        ascendants_over_75_count: 0,
        ascendant_disability_33_count: 0,
        ascendant_disability_65_count: 0,
        ascendant_disability_support_count: 0,
        joint_filing_mode: "none",
        union_dues: 0,
        professional_fees: 0,
        legal_defense_costs: 0,
        disabled_worker_status: "none",
        geographic_mobility: false,
        maternity_eligible_months: 0,
        nursery_expenses_paid: 0,
        large_family_category: "none",
        large_family_extra_children: 0,
        single_parent_two_children: false,
        disabled_descendants_count: 0,
        disabled_ascendants_count: 0,
        spouse_disability_dependant: false,
        contribution_group: "general"
      )
        new(
          gross_income:,
          salary_period:,
          tax_regime_key:,
          tax_year:,
          age_bracket:,
          children_count:,
          children_under_three_count:,
          disability_level:,
          ascendants_count:,
          ascendants_over_75_count:,
          ascendant_disability_33_count:,
          ascendant_disability_65_count:,
          ascendant_disability_support_count:,
          joint_filing_mode:,
          union_dues:,
          professional_fees:,
          legal_defense_costs:,
          disabled_worker_status:,
          geographic_mobility:,
          maternity_eligible_months:,
          nursery_expenses_paid:,
          large_family_category:,
          large_family_extra_children:,
          single_parent_two_children:,
          disabled_descendants_count:,
          disabled_ascendants_count:,
          spouse_disability_dependant:,
          contribution_group:
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
        disability_level:,
        ascendants_count:,
        ascendants_over_75_count:,
        ascendant_disability_33_count:,
        ascendant_disability_65_count:,
        ascendant_disability_support_count:,
        joint_filing_mode:,
        union_dues:,
        professional_fees:,
        legal_defense_costs:,
        disabled_worker_status:,
        geographic_mobility:,
        maternity_eligible_months:,
        nursery_expenses_paid:,
        large_family_category:,
        large_family_extra_children:,
        single_parent_two_children:,
        disabled_descendants_count:,
        disabled_ascendants_count:,
        spouse_disability_dependant:,
        contribution_group:
      )
        @gross_income = gross_income
        @salary_period = salary_period
        @tax_regime_key = tax_regime_key
        @tax_year = tax_year
        @age_bracket = age_bracket
        @children_count = children_count
        @children_under_three_count = children_under_three_count
        @disability_level = disability_level
        @ascendants_count = ascendants_count
        @ascendants_over_75_count = ascendants_over_75_count
        @ascendant_disability_33_count = ascendant_disability_33_count
        @ascendant_disability_65_count = ascendant_disability_65_count
        @ascendant_disability_support_count = ascendant_disability_support_count
        @joint_filing_mode = joint_filing_mode.to_s.presence || "none"
        @union_dues = union_dues
        @professional_fees = professional_fees
        @legal_defense_costs = legal_defense_costs
        @disabled_worker_status = disabled_worker_status
        @geographic_mobility = geographic_mobility
        @maternity_eligible_months = maternity_eligible_months
        @nursery_expenses_paid = nursery_expenses_paid
        @large_family_category = large_family_category
        @large_family_extra_children = large_family_extra_children
        @single_parent_two_children = single_parent_two_children
        @disabled_descendants_count = disabled_descendants_count
        @disabled_ascendants_count = disabled_ascendants_count
        @spouse_disability_dependant = spouse_disability_dependant
        @contribution_group = contribution_group.to_s.presence || "general"
      end

      def call
        validate!

        annual_gross_income = normalize_annual_gross_income
        monthly_gross_income = annual_gross_income / 12
        contribution_base_monthly = monthly_contribution_base_for(monthly_gross_income)
        employee_solidarity_contribution = SocialSecurityOverlays.employee_solidarity(regime:, monthly_gross_income:)
        annual_social_security = (contribution_base_monthly * 12 * parameter_decimal!("employee_social_security_rate")) +
          employee_solidarity_contribution
        employee_expenses = employee_expenses_data
        net_work_income_before_adjustment = [
          annual_gross_income -
            annual_social_security -
            parameter_decimal!("gross_work_income_deduction") -
            employee_expenses.fetch(:total),
          0
        ].max
        work_income_adjustment = work_income_adjustment_for(
          annual_gross_income: annual_gross_income,
          net_work_income_before_adjustment: net_work_income_before_adjustment
        )
        taxable_work_income_before_joint_filing = taxable_work_income_for(
          net_work_income_before_adjustment: net_work_income_before_adjustment,
          work_income_adjustment: work_income_adjustment
        )
        joint_filing_reduction = joint_filing_reduction_for(taxable_work_income_before_joint_filing)
        taxable_work_income = [ taxable_work_income_before_joint_filing - joint_filing_reduction, 0 ].max
        personal_family_minimums = personal_family_minimums_data
        national_family_deductions = national_family_deductions_data
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
          annual_income_tax_before_work_income_adjustment -
            work_income_tax_credit_amount(work_income_adjustment) -
            national_family_deductions.fetch(:total),
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
            disability_level: disability_level,
            ascendants_count: parsed_ascendants_count,
            ascendants_over_75_count: parsed_ascendants_over_75_count,
            ascendant_disability_33_count: parsed_ascendant_disability_33_count,
            ascendant_disability_65_count: parsed_ascendant_disability_65_count,
            ascendant_disability_support_count: parsed_ascendant_disability_support_count,
            joint_filing_mode: joint_filing_mode,
            union_dues: round_currency(employee_expenses.fetch(:union_dues)),
            professional_fees: round_currency(parsed_professional_fees),
            legal_defense_costs: round_currency(parsed_legal_defense_costs),
            disabled_worker_status: disabled_worker_status.to_s.presence || "none",
            geographic_mobility: parsed_geographic_mobility,
            maternity_eligible_months: parsed_maternity_eligible_months,
            nursery_expenses_paid: round_currency(parsed_nursery_expenses_paid),
            large_family_category: large_family_category.to_s.presence || "none",
            large_family_extra_children: parsed_large_family_extra_children,
            single_parent_two_children: parsed_single_parent_two_children,
            disabled_descendants_count: parsed_disabled_descendants_count,
            disabled_ascendants_count: parsed_disabled_ascendants_count,
            spouse_disability_dependant: parsed_spouse_disability_dependant,
            contribution_group: contribution_group
          },
          breakdown: {
            annual_social_security: round_currency(annual_social_security),
            employee_solidarity_contribution: round_currency(employee_solidarity_contribution),
            additional_employee_expenses: round_currency(employee_expenses.fetch(:total)),
            net_work_income_before_adjustment: round_currency(net_work_income_before_adjustment),
            taxable_work_income_before_joint_filing: round_currency(taxable_work_income_before_joint_filing),
            joint_filing_reduction: round_currency(joint_filing_reduction),
            taxable_work_income: round_currency(taxable_work_income),
            state_tax_before_minimum: round_currency(state_tax_before_minimum),
            regional_tax_before_minimum: round_currency(regional_tax_before_minimum),
            state_personal_and_family_minimum: round_currency(personal_family_minimums[:state_amount]),
            regional_personal_and_family_minimum: round_currency(personal_family_minimums[:regional_amount]),
            state_minimum_relief: round_currency(state_minimum_relief),
            regional_minimum_relief: round_currency(regional_minimum_relief),
            work_income_adjustment: round_currency(work_income_adjustment),
            national_family_deductions: round_currency(national_family_deductions.fetch(:total)),
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
            { label: "Additional employee expenses", value: round_currency(employee_expenses.fetch(:total)) },
            { label: "Joint filing reduction", value: round_currency(joint_filing_reduction) },
            { label: "National family deductions", value: round_currency(national_family_deductions.fetch(:total)) },
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

      attr_reader :gross_income, :salary_period, :tax_regime_key, :tax_year, :age_bracket, :children_count,
        :children_under_three_count, :disability_level, :ascendants_count, :ascendants_over_75_count,
        :ascendant_disability_33_count, :ascendant_disability_65_count, :ascendant_disability_support_count,
        :joint_filing_mode, :union_dues, :professional_fees, :legal_defense_costs, :disabled_worker_status,
        :geographic_mobility, :maternity_eligible_months, :nursery_expenses_paid, :large_family_category,
        :large_family_extra_children, :single_parent_two_children, :disabled_descendants_count,
        :disabled_ascendants_count, :spouse_disability_dependant, :contribution_group

      def validate!
        errors = []
        errors << "gross_income must be a number greater than 0" if parsed_gross_income <= 0
        errors << "gross_income is too large for the current calculator" if parsed_gross_income > 50_000_000
        errors << "salary_period must be YEAR or MONTH" unless %w[YEAR MONTH].include?(normalized_salary_period)
        errors << "tax_regime_key must point to a supported employee regime" if regime.blank?
        errors.concat(
          PersonalFamilyMinimums.validation_errors(
            age_bracket:,
            children_count:,
            children_under_three_count:,
            disability_level:,
            ascendants_count:,
            ascendants_over_75_count:,
            ascendant_disability_33_count:,
            ascendant_disability_65_count:,
            ascendant_disability_support_count:
          )
        )
        errors << "joint_filing_mode is not supported" unless %w[none married_unit single_parent_unit].include?(joint_filing_mode)
        errors.concat(
          EmployeeExpenses.validation_errors(
            union_dues:,
            professional_fees:,
            legal_defense_costs:,
            disabled_worker_status:
          )
        )
        errors.concat(national_family_deduction_validation_errors)
        raise ValidationError.new(errors) if errors.any?
      end

      def regime
        @regime ||= find_regime(category: "employee", tax_year: tax_year, country: country)
      end

      def country
        @country ||= CalculationRouter.country
      end

      def metadata
        build_regime_metadata(calculator_version: "spain-common-employee-v1")
      end

      def assumptions
        base_assumptions = [
          "Spain, tax year #{tax_year}.",
          "Resident salaried employee in #{regime.region} under the common IRPF regime.",
          "Profile inputs: #{personal_family_minimums_data[:summary]}.",
          "Employment expenses applied: #{employee_expenses_data[:summary]}. Joint filing: #{joint_filing_mode.tr('_', ' ')}. National family deductions: #{national_family_deductions_data[:summary]}.",
          "Standard indefinite contract assumptions for employee Social Security.",
          "Employee Social Security uses the official worker rates and bases stored for the selected year.",
          "Contribution group #{contribution_group} is stored for payroll context; the current employee estimate applies the shared general worker rate and base caps.",
          "Regional IRPF currently covers the common-regime autonomous communities plus Ceuta and Melilla.",
          "Age, children, ascendants, and taxpayer/ascendant disability inputs are applied through the official common personal-and-family minimum structure, using the region-specific taxpayer base minimum already stored for the selected jurisdiction.",
          "Regional deductions, pension reductions, donations, double-taxation relief, and legacy housing deductions are not included."
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
          disability_level:,
          ascendants_count:,
          ascendants_over_75_count:,
          ascendant_disability_33_count:,
          ascendant_disability_65_count:,
          ascendant_disability_support_count:
        )[:children_under_three_count]
      end

      def parsed_ascendants_count
        personal_family_minimums_data[:ascendants_count]
      end

      def parsed_ascendants_over_75_count
        personal_family_minimums_data[:ascendants_over_75_count]
      end

      def parsed_ascendant_disability_33_count
        personal_family_minimums_data[:ascendant_disability_33_count]
      end

      def parsed_ascendant_disability_65_count
        personal_family_minimums_data[:ascendant_disability_65_count]
      end

      def parsed_ascendant_disability_support_count
        personal_family_minimums_data[:ascendant_disability_support_count]
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

      def employee_expenses_data
        @employee_expenses_data ||= EmployeeExpenses.call(
          regime:,
          union_dues:,
          professional_fees:,
          legal_defense_costs:,
          disabled_worker_status:,
          geographic_mobility:
        )
      end

      def national_family_deductions_data
        @national_family_deductions_data ||= NationalFamilyDeductions.call(
          regime:,
          **national_family_deduction_inputs
        )
      end

      def national_family_deduction_validation_errors
        NationalFamilyDeductions.validation_errors(**national_family_deduction_inputs)
      end

      def national_family_deduction_inputs
        {
          maternity_eligible_months:,
          nursery_expenses_paid:,
          large_family_category:,
          large_family_extra_children:,
          single_parent_two_children:,
          disabled_descendants_count:,
          disabled_ascendants_count:,
          spouse_disability_dependant:
        }
      end

      def joint_filing_reduction_for(taxable_income)
        reduction =
          case joint_filing_mode
          when "married_unit"
            parameter_decimal!("joint_filing_married_reduction")
          when "single_parent_unit"
            parameter_decimal!("joint_filing_single_parent_reduction")
          else
            BigDecimal("0")
          end

        [ taxable_income, reduction ].min
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
          disability_level:,
          ascendants_count:,
          ascendants_over_75_count:,
          ascendant_disability_33_count:,
          ascendant_disability_65_count:,
          ascendant_disability_support_count:
        )
      end

      def parsed_union_dues
        @parsed_union_dues ||= decimal(union_dues)
      end

      def parsed_professional_fees
        @parsed_professional_fees ||= decimal(professional_fees)
      end

      def parsed_legal_defense_costs
        @parsed_legal_defense_costs ||= decimal(legal_defense_costs)
      end

      def parsed_nursery_expenses_paid
        @parsed_nursery_expenses_paid ||= decimal(nursery_expenses_paid)
      end

      def parsed_maternity_eligible_months
        @parsed_maternity_eligible_months ||= integer(maternity_eligible_months)
      end

      def parsed_large_family_extra_children
        @parsed_large_family_extra_children ||= integer(large_family_extra_children)
      end

      def parsed_disabled_descendants_count
        @parsed_disabled_descendants_count ||= integer(disabled_descendants_count)
      end

      def parsed_disabled_ascendants_count
        @parsed_disabled_ascendants_count ||= integer(disabled_ascendants_count)
      end

      def parsed_geographic_mobility
        boolean(geographic_mobility)
      end

      def parsed_single_parent_two_children
        boolean(single_parent_two_children)
      end

      def parsed_spouse_disability_dependant
        boolean(spouse_disability_dependant)
      end
    end
  end
end
