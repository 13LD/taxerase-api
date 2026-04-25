module Taxerase
  module Spain
    class CalculationRouter
      extend Taxerase::Support::CountryRouter

      class UnsupportedRegimeError < Taxerase::UnsupportedRegimeError; end

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
        disability_level: "none",
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
        contribution_group: "general",
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
        age_bracket = age_bracket.presence || "under_65"
        children_count = children_count.nil? ? 0 : children_count
        children_under_three_count = children_under_three_count.nil? ? 0 : children_under_three_count
        disability_level = disability_level.presence || "none"
        common_profile_kwargs = {
          age_bracket:,
          children_count:,
          children_under_three_count:,
          disability_level:,
          ascendants_count: value_or_default(ascendants_count, 0),
          ascendants_over_75_count: value_or_default(ascendants_over_75_count, 0),
          ascendant_disability_33_count: value_or_default(ascendant_disability_33_count, 0),
          ascendant_disability_65_count: value_or_default(ascendant_disability_65_count, 0),
          ascendant_disability_support_count: value_or_default(ascendant_disability_support_count, 0),
          joint_filing_mode: joint_filing_mode.presence || "none",
          maternity_eligible_months: value_or_default(maternity_eligible_months, 0),
          nursery_expenses_paid: value_or_default(nursery_expenses_paid, 0),
          large_family_category: large_family_category.presence || "none",
          large_family_extra_children: value_or_default(large_family_extra_children, 0),
          single_parent_two_children: value_or_default(single_parent_two_children, false),
          disabled_descendants_count: value_or_default(disabled_descendants_count, 0),
          disabled_ascendants_count: value_or_default(disabled_ascendants_count, 0),
          spouse_disability_dependant: value_or_default(spouse_disability_dependant, false)
        }
        resolved_input_currency_code = input_currency_handler.resolve_input_currency_code(input_currency_code)
        regime = regime_for!(tax_regime_key.presence || default_regime_key(tax_year), tax_year)
        calculator = SUPPORTED_METHODS[regime.parameter_text("calculation_method")]

        raise unsupported_regime_error_for(regime) unless calculator

        result = if calculator == CommonRegimeSelfEmployedCalculator
          calculator.call(
            gross_income:,
            salary_period:,
            tax_regime_key: regime.key,
            tax_year:,
            deductible_expenses:,
            **common_profile_kwargs,
            self_employed_estimation_method: self_employed_estimation_method.presence || "direct_simplified",
            home_office_supply_expenses: value_or_default(home_office_supply_expenses, 0),
            home_office_ownership_expenses: value_or_default(home_office_ownership_expenses, 0),
            home_office_business_use_percentage: value_or_default(home_office_business_use_percentage, 0),
            meals_expenses: value_or_default(meals_expenses, 0),
            reta_contribution_mode: reta_contribution_mode.presence || "standard",
            family_collaborator: value_or_default(family_collaborator, false),
            corporate_self_employed: value_or_default(corporate_self_employed, false),
            apply_reta_pluriactivity: value_or_default(apply_reta_pluriactivity, false),
            employment_common_contingencies_paid: value_or_default(employment_common_contingencies_paid, 0)
          )
        elsif calculator == CommonRegimeEmployeeCalculator
          calculator.call(
            gross_income:,
            salary_period:,
            tax_regime_key: regime.key,
            tax_year:,
            **common_profile_kwargs,
            union_dues: value_or_default(union_dues, 0),
            professional_fees: value_or_default(professional_fees, 0),
            legal_defense_costs: value_or_default(legal_defense_costs, 0),
            disabled_worker_status: disabled_worker_status.presence || "none",
            geographic_mobility: value_or_default(geographic_mobility, false),
            contribution_group: contribution_group.presence || "general"
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

      def self.value_or_default(value, default)
        value.nil? ? default : value
      end
    end
  end
end
