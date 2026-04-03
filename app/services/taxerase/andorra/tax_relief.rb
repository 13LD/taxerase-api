module Taxerase
  module Andorra
    module TaxRelief
      DISABILITY_LEVELS = %w[none recognized_disability].freeze
      BOOLEAN_VALUES = [ true, false, "true", "false", "1", "0", 1, 0, nil, "" ].freeze

      def self.validation_errors(
        children_count:,
        disability_level:,
        spouse_without_income:,
        mortgage_interest:,
        pension_contributions:,
        alimony_paid:
      )
        errors = []
        errors << "children_count must be 0 or greater" if parse_count(children_count).negative?
        errors << "disability_level must be one of: #{DISABILITY_LEVELS.join(', ')}" unless DISABILITY_LEVELS.include?(disability_level.to_s)
        errors << "spouse_without_income must be true or false" unless BOOLEAN_VALUES.include?(spouse_without_income)
        errors << "mortgage_interest must be 0 or greater" if parse_amount(mortgage_interest).negative?
        errors << "pension_contributions must be 0 or greater" if parse_amount(pension_contributions).negative?
        errors << "alimony_paid must be 0 or greater" if parse_amount(alimony_paid).negative?
        errors
      rescue ArgumentError
        [ "children_count must be 0 or greater" ]
      end

      def self.reductions(
        regime:,
        children_count:,
        disability_level:,
        spouse_without_income:,
        mortgage_interest:,
        pension_contributions:,
        alimony_paid:,
        net_general_income:,
        parameter_decimal:
      )
        taxpayer_reduction = if boolean_value?(spouse_without_income)
          parameter_decimal.call("personal_reduction_spouse_without_income")
        elsif disability_level.to_s == "recognized_disability"
          parameter_decimal.call("personal_reduction_disability")
        else
          parameter_decimal.call("personal_reduction_default")
        end

        dependent_reduction = parse_count(children_count) * parameter_decimal.call("dependent_reduction")
        pension_reduction = [
          parse_amount(pension_contributions),
          parameter_decimal.call("pension_contribution_reduction_cap"),
          [ net_general_income, BigDecimal("0") ].max * parameter_decimal.call("pension_contribution_income_rate_cap")
        ].min
        alimony_reduction = parse_amount(alimony_paid)
        mortgage_interest_credit = [
          parse_amount(mortgage_interest) * parameter_decimal.call("mortgage_interest_credit_rate"),
          parameter_decimal.call("mortgage_interest_credit_cap")
        ].min

        {
          taxpayer_reduction: taxpayer_reduction,
          dependent_reduction: dependent_reduction,
          pension_reduction: pension_reduction,
          alimony_reduction: alimony_reduction,
          total_base_reductions: taxpayer_reduction + dependent_reduction + pension_reduction + alimony_reduction,
          mortgage_interest_credit: mortgage_interest_credit
        }
      end

      def self.parse_count(value)
        Integer(value.to_s)
      end

      def self.parse_amount(value)
        BigDecimal(value.to_s.presence || "0")
      end

      def self.boolean_value?(value)
        value == true || value.to_s == "true" || value.to_s == "1"
      end
    end
  end
end
