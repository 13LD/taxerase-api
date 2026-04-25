module Taxerase
  module Andorra
    module TaxRelief
      DISABILITY_LEVELS = %w[none recognized_disability].freeze
      BOOLEAN_VALUES = [ true, false, "true", "false", "1", "0", 1, 0, nil, "" ].freeze

      def self.validation_errors(
        children_count:,
        disability_level:,
        has_spouse_or_partner:,
        spouse_without_income:,
        spouse_general_income:,
        disabled_dependents_count:,
        mortgage_interest:,
        home_acquisition_investment: 0,
        affordable_rental_housing_investment: 0,
        higher_education_tuition: 0,
        pension_contributions:,
        alimony_paid:
      )
        errors = []
        errors << "children_count must be 0 or greater" if parse_count(children_count).negative?
        errors << "disabled_dependents_count must be 0 or greater" if parse_count(disabled_dependents_count).negative?
        errors << "disability_level must be one of: #{DISABILITY_LEVELS.join(', ')}" unless DISABILITY_LEVELS.include?(disability_level.to_s)
        errors << "has_spouse_or_partner must be true or false" unless BOOLEAN_VALUES.include?(has_spouse_or_partner)
        errors << "spouse_without_income must be true or false" unless BOOLEAN_VALUES.include?(spouse_without_income)
        errors << "spouse_general_income must be 0 or greater" if parse_amount(spouse_general_income).negative?
        errors << "mortgage_interest must be 0 or greater" if parse_amount(mortgage_interest).negative?
        errors << "home_acquisition_investment must be 0 or greater" if parse_amount(home_acquisition_investment).negative?
        if parse_amount(affordable_rental_housing_investment).negative?
          errors << "affordable_rental_housing_investment must be 0 or greater"
        end
        errors << "higher_education_tuition must be 0 or greater" if parse_amount(higher_education_tuition).negative?
        errors << "pension_contributions must be 0 or greater" if parse_amount(pension_contributions).negative?
        errors << "alimony_paid must be 0 or greater" if parse_amount(alimony_paid).negative?
        errors
      rescue ArgumentError
        [ "children_count must be 0 or greater" ]
      end

      def self.reductions(
        children_count:,
        disability_level:,
        has_spouse_or_partner:,
        spouse_without_income:,
        spouse_general_income:,
        disabled_dependents_count:,
        mortgage_interest:,
        home_acquisition_investment: 0,
        affordable_rental_housing_investment: 0,
        higher_education_tuition: 0,
        pension_contributions:,
        alimony_paid:,
        net_general_income:,
        parameter_decimal:
      )
        taxpayer_reduction_default = parameter_decimal.call("personal_reduction_default")
        disability_reduction = disability_level.to_s == "recognized_disability" ? parameter_decimal.call("personal_reduction_disability") : taxpayer_reduction_default
        spouse_phase_in_increment = spouse_phase_in_increment_for(
          has_spouse_or_partner: has_spouse_or_partner,
          spouse_without_income: spouse_without_income,
          spouse_general_income: spouse_general_income,
          taxpayer_reduction_default: taxpayer_reduction_default,
          taxpayer_reduction_cap: parameter_decimal.call("personal_reduction_spouse_without_income")
        )
        taxpayer_reduction = [ disability_reduction, taxpayer_reduction_default + spouse_phase_in_increment ].max

        dependent_reduction = parse_count(children_count) * parameter_decimal.call("dependent_reduction")
        dependent_disability_uplift = parse_count(disabled_dependents_count) * parameter_decimal.call("family_member_disability_extra")
        habitual_home_investment_reduction = [
          home_investment_amount(mortgage_interest:, home_acquisition_investment:) *
            parameter_decimal.call("habitual_home_investment_reduction_rate"),
          parameter_decimal.call("habitual_home_investment_reduction_cap")
        ].min
        affordable_rental_housing_investment_reduction = [
          parse_amount(affordable_rental_housing_investment) *
            parameter_decimal.call("affordable_rental_housing_investment_reduction_rate"),
          parameter_decimal.call("affordable_rental_housing_investment_reduction_cap")
        ].min
        higher_education_tuition_reduction = [
          parse_amount(higher_education_tuition),
          parameter_decimal.call("higher_education_tuition_reduction_cap")
        ].min
        pension_reduction = [
          parse_amount(pension_contributions),
          parameter_decimal.call("pension_contribution_reduction_cap"),
          [ net_general_income, BigDecimal("0") ].max * parameter_decimal.call("pension_contribution_income_rate_cap")
        ].min
        alimony_reduction = parse_amount(alimony_paid)
        total_base_reductions =
          taxpayer_reduction +
          dependent_reduction +
          dependent_disability_uplift +
          habitual_home_investment_reduction +
          affordable_rental_housing_investment_reduction +
          higher_education_tuition_reduction +
          pension_reduction +
          alimony_reduction

        {
          taxpayer_reduction: taxpayer_reduction,
          spouse_phase_in_increment: spouse_phase_in_increment,
          dependent_reduction: dependent_reduction,
          dependent_disability_uplift: dependent_disability_uplift,
          habitual_home_investment_reduction: habitual_home_investment_reduction,
          affordable_rental_housing_investment_reduction: affordable_rental_housing_investment_reduction,
          higher_education_tuition_reduction: higher_education_tuition_reduction,
          pension_reduction: pension_reduction,
          alimony_reduction: alimony_reduction,
          total_base_reductions: total_base_reductions
        }
      end

      def self.spouse_phase_in_increment_for(
        has_spouse_or_partner:,
        spouse_without_income:,
        spouse_general_income:,
        taxpayer_reduction_default:,
        taxpayer_reduction_cap:
      )
        return BigDecimal("0") unless boolean_value?(has_spouse_or_partner)

        spouse_income = parse_amount(spouse_general_income)
        spouse_based_reduction =
          if boolean_value?(spouse_without_income)
            taxpayer_reduction_cap
          elsif spouse_income.positive? && spouse_income < taxpayer_reduction_default
            [ taxpayer_reduction_cap - spouse_income, taxpayer_reduction_default ].max
          else
            taxpayer_reduction_default
          end

        [ spouse_based_reduction - taxpayer_reduction_default, BigDecimal("0") ].max
      end

      def self.parse_count(value)
        Integer(value.to_s)
      end

      def self.parse_amount(value)
        BigDecimal(value.to_s.presence || "0")
      end

      def self.home_investment_amount(mortgage_interest:, home_acquisition_investment:)
        parsed_home_acquisition_investment = parse_amount(home_acquisition_investment)
        return parsed_home_acquisition_investment if parsed_home_acquisition_investment.positive?

        parse_amount(mortgage_interest)
      end

      def self.boolean_value?(value)
        value == true || value.to_s == "true" || value.to_s == "1"
      end
    end
  end
end
