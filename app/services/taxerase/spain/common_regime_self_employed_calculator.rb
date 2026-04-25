module Taxerase
  module Spain
    class CommonRegimeSelfEmployedCalculator
      include Taxerase::Support::RegimeBackedCalculation
      include InputNormalization

      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      CALCULATION_METHOD = "common_regime_self_employed_v1".freeze
      COUNTRY_CODE = "ES".freeze

      def self.call(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        deductible_expenses:,
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
        maternity_eligible_months: 0,
        nursery_expenses_paid: 0,
        large_family_category: "none",
        large_family_extra_children: 0,
        single_parent_two_children: false,
        disabled_descendants_count: 0,
        disabled_ascendants_count: 0,
        spouse_disability_dependant: false,
        self_employed_estimation_method: "direct_simplified",
        home_office_supply_expenses: 0,
        home_office_ownership_expenses: 0,
        home_office_business_use_percentage: 0,
        meals_expenses: 0,
        reta_contribution_mode: "standard",
        family_collaborator: false,
        corporate_self_employed: false,
        apply_reta_pluriactivity: false,
        employment_common_contingencies_paid: 0
      )
        new(
          gross_income:,
          salary_period:,
          tax_regime_key:,
          tax_year:,
          deductible_expenses:,
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
          maternity_eligible_months:,
          nursery_expenses_paid:,
          large_family_category:,
          large_family_extra_children:,
          single_parent_two_children:,
          disabled_descendants_count:,
          disabled_ascendants_count:,
          spouse_disability_dependant:,
          self_employed_estimation_method:,
          home_office_supply_expenses:,
          home_office_ownership_expenses:,
          home_office_business_use_percentage:,
          meals_expenses:,
          reta_contribution_mode:,
          family_collaborator:,
          corporate_self_employed:,
          apply_reta_pluriactivity:,
          employment_common_contingencies_paid:
        ).call
      end

      def initialize(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        deductible_expenses:,
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
        maternity_eligible_months:,
        nursery_expenses_paid:,
        large_family_category:,
        large_family_extra_children:,
        single_parent_two_children:,
        disabled_descendants_count:,
        disabled_ascendants_count:,
        spouse_disability_dependant:,
        self_employed_estimation_method:,
        home_office_supply_expenses:,
        home_office_ownership_expenses:,
        home_office_business_use_percentage:,
        meals_expenses:,
        reta_contribution_mode:,
        family_collaborator:,
        corporate_self_employed:,
        apply_reta_pluriactivity:,
        employment_common_contingencies_paid:
      )
        @gross_income = gross_income
        @salary_period = salary_period
        @tax_regime_key = tax_regime_key
        @tax_year = tax_year
        @deductible_expenses = deductible_expenses
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
        @maternity_eligible_months = maternity_eligible_months
        @nursery_expenses_paid = nursery_expenses_paid
        @large_family_category = large_family_category
        @large_family_extra_children = large_family_extra_children
        @single_parent_two_children = single_parent_two_children
        @disabled_descendants_count = disabled_descendants_count
        @disabled_ascendants_count = disabled_ascendants_count
        @spouse_disability_dependant = spouse_disability_dependant
        @self_employed_estimation_method = self_employed_estimation_method.to_s.presence || "direct_simplified"
        @home_office_supply_expenses = home_office_supply_expenses
        @home_office_ownership_expenses = home_office_ownership_expenses
        @home_office_business_use_percentage = home_office_business_use_percentage
        @meals_expenses = meals_expenses
        @reta_contribution_mode = reta_contribution_mode.to_s.presence || "standard"
        @family_collaborator = family_collaborator
        @corporate_self_employed = corporate_self_employed
        @apply_reta_pluriactivity = apply_reta_pluriactivity
        @employment_common_contingencies_paid = employment_common_contingencies_paid
      end

      def call
        validate!

        annual_gross_income = normalize_annual_gross_income
        expense_profile = self_employed_expenses_data
        annual_deductible_expenses = expense_profile.fetch(:direct_expenses_total)
        net_income_before_social_security =
          if expense_profile.fetch(:estimation_method) == "modules"
            annual_gross_income * expense_profile.fetch(:modules_net_income_rate)
          else
            [ annual_gross_income - annual_deductible_expenses, 0 ].max
          end
        monthly_net_returns_for_social_security = average_monthly_net_returns_for_social_security(net_income_before_social_security)
        social_security_band = social_security_band_for(monthly_net_returns_for_social_security)
        monthly_social_security_base = monthly_social_security_base_for(social_security_band)
        standard_social_security = monthly_social_security_base * 12 * parameter_decimal!("self_employed_social_security_rate")
        annual_social_security = SocialSecurityOverlays.reta_contribution(
          regime:,
          standard_contribution: standard_social_security,
          reta_contribution_mode:,
          family_collaborator: parsed_family_collaborator,
          corporate_self_employed: parsed_corporate_self_employed
        )
        reta_pluriactivity_refund = parsed_apply_reta_pluriactivity ? SocialSecurityOverlays.pluriactivity_refund(
          regime:,
          employment_common_contingencies_paid:,
          annual_reta_contribution: annual_social_security
        ) : BigDecimal("0")
        activity_income_before_generic_deduction = [ net_income_before_social_security - annual_social_security, 0 ].max
        difficult_to_justify_deduction = difficult_to_justify_deduction_for(activity_income_before_generic_deduction)
        taxable_activity_income = [ activity_income_before_generic_deduction - difficult_to_justify_deduction, 0 ].max
        joint_filing_reduction = joint_filing_reduction_for(taxable_activity_income)
        taxable_activity_income_after_joint_filing = [ taxable_activity_income - joint_filing_reduction, 0 ].max
        personal_family_minimums = personal_family_minimums_data
        national_family_deductions = national_family_deductions_data
        state_brackets = regime.brackets_for("state_irpf")
        regional_brackets = regime.brackets_for("regional_irpf")
        state_tax_before_minimum = ProgressiveTax.call(amount: taxable_activity_income_after_joint_filing, brackets: state_brackets)
        regional_tax_before_minimum = ProgressiveTax.call(amount: taxable_activity_income_after_joint_filing, brackets: regional_brackets)
        state_minimum_relief = ProgressiveTax.call(
          amount: [ taxable_activity_income_after_joint_filing, personal_family_minimums[:state_amount] ].min,
          brackets: state_brackets
        )
        regional_minimum_relief = ProgressiveTax.call(
          amount: [ taxable_activity_income_after_joint_filing, personal_family_minimums[:regional_amount] ].min,
          brackets: regional_brackets
        )
        annual_income_tax = [
          state_tax_before_minimum +
            regional_tax_before_minimum -
            state_minimum_relief -
            regional_minimum_relief -
            national_family_deductions.fetch(:total),
          0
        ].max
        total_tax = annual_income_tax + annual_social_security - reta_pluriactivity_refund
        annual_net_income = annual_gross_income - annual_deductible_expenses - total_tax

        {
          metadata: metadata,
          input: {
            gross_income: round_currency(parsed_gross_income),
            deductible_expenses: round_currency(annual_deductible_expenses),
            salary_period: normalized_salary_period,
            tax_year: tax_year,
            annual_gross_income: round_currency(annual_gross_income),
            monthly_gross_income: round_currency(annual_gross_income / 12),
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
            maternity_eligible_months: parsed_maternity_eligible_months,
            nursery_expenses_paid: round_currency(parsed_nursery_expenses_paid),
            large_family_category: large_family_category.to_s.presence || "none",
            large_family_extra_children: parsed_large_family_extra_children,
            single_parent_two_children: parsed_single_parent_two_children,
            disabled_descendants_count: parsed_disabled_descendants_count,
            disabled_ascendants_count: parsed_disabled_ascendants_count,
            spouse_disability_dependant: parsed_spouse_disability_dependant,
            self_employed_estimation_method: self_employed_estimation_method,
            home_office_supply_expenses: round_currency(parsed_home_office_supply_expenses),
            home_office_ownership_expenses: round_currency(parsed_home_office_ownership_expenses),
            home_office_business_use_percentage: round_currency(parsed_home_office_business_use_percentage),
            meals_expenses: round_currency(parsed_meals_expenses),
            reta_contribution_mode: reta_contribution_mode,
            family_collaborator: parsed_family_collaborator,
            corporate_self_employed: parsed_corporate_self_employed,
            apply_reta_pluriactivity: parsed_apply_reta_pluriactivity,
            employment_common_contingencies_paid: round_currency(parsed_employment_common_contingencies_paid)
          },
          breakdown: {
            annual_deductible_expenses: round_currency(annual_deductible_expenses),
            home_office_supply_deduction: round_currency(expense_profile.fetch(:home_office_supply_deduction)),
            home_office_ownership_deduction: round_currency(expense_profile.fetch(:home_office_ownership_deduction)),
            meals_deduction: round_currency(expense_profile.fetch(:meals_deduction)),
            net_income_before_social_security: round_currency(net_income_before_social_security),
            monthly_net_returns_for_social_security: round_currency(monthly_net_returns_for_social_security),
            monthly_social_security_base: round_currency(monthly_social_security_base),
            standard_social_security: round_currency(standard_social_security),
            annual_social_security: round_currency(annual_social_security),
            reta_pluriactivity_refund: round_currency(reta_pluriactivity_refund),
            difficult_to_justify_deduction: round_currency(difficult_to_justify_deduction),
            taxable_activity_income: round_currency(taxable_activity_income),
            joint_filing_reduction: round_currency(joint_filing_reduction),
            taxable_activity_income_after_joint_filing: round_currency(taxable_activity_income_after_joint_filing),
            state_tax_before_minimum: round_currency(state_tax_before_minimum),
            regional_tax_before_minimum: round_currency(regional_tax_before_minimum),
            state_personal_and_family_minimum: round_currency(personal_family_minimums[:state_amount]),
            regional_personal_and_family_minimum: round_currency(personal_family_minimums[:regional_amount]),
            state_minimum_relief: round_currency(state_minimum_relief),
            regional_minimum_relief: round_currency(regional_minimum_relief),
            national_family_deductions: round_currency(national_family_deductions.fetch(:total)),
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
            { label: "RETA pluriactivity refund estimate", value: round_currency(reta_pluriactivity_refund) },
            { label: "5% difficult-to-justify deduction", value: round_currency(difficult_to_justify_deduction) },
            { label: "Joint filing reduction", value: round_currency(joint_filing_reduction) },
            { label: "National family deductions", value: round_currency(national_family_deductions.fetch(:total)) },
            { label: "Taxable activity income", value: round_currency(taxable_activity_income) },
            { label: "State personal and family minimum", value: round_currency(personal_family_minimums[:state_amount]) },
            { label: "#{regime.region} personal and family minimum", value: round_currency(personal_family_minimums[:regional_amount]) },
            { label: "Income tax", value: round_currency(annual_income_tax) },
            { label: "Total tax", value: round_currency(total_tax) },
            { label: "Estimated monthly RETA base", value: round_currency(monthly_social_security_base) }
          ],
          assumptions: assumptions(social_security_band),
          sources: regime.source_links
        }
      end

      private

      attr_reader :gross_income, :salary_period, :tax_regime_key, :tax_year, :deductible_expenses, :age_bracket,
        :children_count, :children_under_three_count, :disability_level, :ascendants_count, :ascendants_over_75_count,
        :ascendant_disability_33_count, :ascendant_disability_65_count, :ascendant_disability_support_count,
        :joint_filing_mode, :maternity_eligible_months, :nursery_expenses_paid, :large_family_category,
        :large_family_extra_children, :single_parent_two_children, :disabled_descendants_count,
        :disabled_ascendants_count, :spouse_disability_dependant, :self_employed_estimation_method,
        :home_office_supply_expenses, :home_office_ownership_expenses, :home_office_business_use_percentage,
        :meals_expenses, :reta_contribution_mode, :family_collaborator, :corporate_self_employed,
        :apply_reta_pluriactivity, :employment_common_contingencies_paid

      def validate!
        errors = []
        errors << "gross_income must be a number greater than 0" if parsed_gross_income <= 0
        errors << "gross_income is too large for the current calculator" if parsed_gross_income > 50_000_000
        errors << "salary_period must be YEAR or MONTH" unless %w[YEAR MONTH].include?(normalized_salary_period)
        errors << "tax_regime_key must point to a supported self-employed regime" if regime.blank?
        errors << "joint_filing_mode is not supported" unless %w[none married_unit single_parent_unit].include?(joint_filing_mode)
        errors << "reta_contribution_mode is not supported" unless SocialSecurityOverlays.validate_reta_mode(reta_contribution_mode)
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
        errors.concat(self_employed_expense_validation_errors)
        errors.concat(national_family_deduction_validation_errors)
        raise ValidationError.new(errors) if errors.any?
      end

      def regime
        @regime ||= find_regime(category: "self_employed", tax_year: tax_year, country: country)
      end

      def country
        @country ||= CalculationRouter.country
      end

      def metadata
        build_regime_metadata(calculator_version: "spain-common-self-employed-v1")
      end

      def assumptions(social_security_band)
        [
          "Spain, tax year #{tax_year}.",
          "Resident self-employed person in #{regime.region} using #{self_employed_expenses_data[:summary]}.",
          "Profile inputs: #{personal_family_minimums_data[:summary]}. Joint filing: #{joint_filing_mode.tr('_', ' ')}. National family deductions: #{national_family_deductions_data[:summary]}.",
          "User-entered deductible expenses, home-office expenses, and meals are treated as documented business-expense classes for annual IRPF estimate purposes.",
          "The RETA band is estimated from annual revenue minus deductible expenses, less the official 7% generic expense adjustment.",
          "The monthly RETA contribution basis is set to the minimum basis of the matching official band (#{social_security_band.label}).",
          "RETA mode: #{SocialSecurityOverlays.reta_mode_label(reta_contribution_mode)}.",
          "The 5% difficult-to-justify deduction is applied with the official annual cap only for direct estimation simplified.",
          "Age, children, ascendants, and taxpayer/ascendant-disability inputs are applied through the official common personal-and-family minimum structure, using the region-specific taxpayer base minimum already stored for the selected jurisdiction.",
          "Model 130 deadlines, VAT/invoicing workflows, regional deductions, and later RETA regularization workflows are not included in this calculator result."
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

      def parsed_children_count
        @parsed_children_count ||= personal_family_minimums_data[:children_count]
      end

      def parsed_children_under_three_count
        @parsed_children_under_three_count ||= personal_family_minimums_data[:children_under_three_count]
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

      def self_employed_expenses_data
        @self_employed_expenses_data ||= SelfEmployedExpenses.call(
          regime:,
          **self_employed_expense_inputs
        )
      end

      def self_employed_expense_validation_errors
        SelfEmployedExpenses.validation_errors(**self_employed_expense_inputs)
      end

      def self_employed_expense_inputs
        {
          deductible_expenses:,
          home_office_supply_expenses:,
          home_office_ownership_expenses:,
          home_office_business_use_percentage:,
          meals_expenses:,
          self_employed_estimation_method:
        }
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

      def monthly_social_security_base_for(social_security_band)
        base = social_security_band.base_min.to_d
        return base unless parsed_corporate_self_employed

        [ base, parameter_decimal!("corporate_self_employed_min_base") ].max
      end

      def difficult_to_justify_deduction_for(activity_income_before_generic_deduction)
        return BigDecimal("0") unless self_employed_estimation_method == "direct_simplified"

        [
          activity_income_before_generic_deduction * parameter_decimal!("difficult_to_justify_deduction_rate"),
          parameter_decimal!("difficult_to_justify_deduction_cap")
        ].min
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

      def parsed_nursery_expenses_paid
        @parsed_nursery_expenses_paid ||= decimal(nursery_expenses_paid)
      end

      def parsed_home_office_supply_expenses
        @parsed_home_office_supply_expenses ||= decimal(home_office_supply_expenses)
      end

      def parsed_home_office_ownership_expenses
        @parsed_home_office_ownership_expenses ||= decimal(home_office_ownership_expenses)
      end

      def parsed_home_office_business_use_percentage
        @parsed_home_office_business_use_percentage ||= decimal(home_office_business_use_percentage)
      end

      def parsed_meals_expenses
        @parsed_meals_expenses ||= decimal(meals_expenses)
      end

      def parsed_employment_common_contingencies_paid
        @parsed_employment_common_contingencies_paid ||= decimal(employment_common_contingencies_paid)
      end

      def parsed_single_parent_two_children
        boolean(single_parent_two_children)
      end

      def parsed_spouse_disability_dependant
        boolean(spouse_disability_dependant)
      end

      def parsed_family_collaborator
        boolean(family_collaborator)
      end

      def parsed_corporate_self_employed
        boolean(corporate_self_employed)
      end

      def parsed_apply_reta_pluriactivity
        boolean(apply_reta_pluriactivity)
      end
    end
  end
end
