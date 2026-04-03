module Taxerase
  module Portugal
    module TaxDeductions
      DISABILITY_LEVELS = %w[none disability_60_plus].freeze

      AMOUNT_INPUT_KEYS = %i[
        general_family_expenses
        health_expenses
        education_expenses
        housing_rent
        alimony_paid
        care_home_expenses
        domestic_work_expenses
      ].freeze

      def self.validation_errors(
        disability_level:,
        ascendants_count:,
        general_family_expenses:,
        health_expenses:,
        education_expenses:,
        housing_rent:,
        alimony_paid:,
        care_home_expenses:,
        domestic_work_expenses:
      )
        errors = []
        errors << "disability_level must be one of: #{DISABILITY_LEVELS.join(', ')}" unless DISABILITY_LEVELS.include?(disability_level.to_s)
        validate_count("ascendants_count", ascendants_count, errors)

        {
          general_family_expenses:,
          health_expenses:,
          education_expenses:,
          housing_rent:,
          alimony_paid:,
          care_home_expenses:,
          domestic_work_expenses:
        }.each do |key, value|
          validate_amount(key, value, errors)
        end

        errors
      end

      def self.employee_specific_deduction(regime:, annual_social_security:)
        [ regime.parameter_decimal!("specific_deduction_floor"), annual_social_security ].max
      end

      def self.documentation_support_base(regime:, annual_social_security:, annual_gross_income:)
        social_security_cap = annual_gross_income * BigDecimal("0.10")
        supported_social_security = [ annual_social_security, social_security_cap ].min

        [ regime.parameter_decimal!("specific_deduction_floor"), supported_social_security ].max
      end

      def self.personal_tax_deductions(
        regime:,
        children_count:,
        children_under_three_count:,
        disability_level:,
        ascendants_count:,
        general_family_expenses:,
        health_expenses:,
        education_expenses:,
        housing_rent:,
        alimony_paid:,
        care_home_expenses:,
        domestic_work_expenses:
      )
        parsed_children_count = parse_count(children_count)
        parsed_children_under_three_count = parse_count(children_under_three_count)
        parsed_ascendants_count = parse_count(ascendants_count)
        dependent_deduction = regime.parameter_decimal!("dependent_deduction") * parsed_children_count
        dependent_under_three_deduction =
          regime.parameter_decimal!("dependent_under_three_bonus") * parsed_children_under_three_count
        ascendant_deduction = regime.parameter_decimal!("ascendant_deduction") * parsed_ascendants_count
        ascendant_deduction += regime.parameter_decimal!("single_ascendant_bonus") if parsed_ascendants_count == 1
        disability_deduction =
          disability_level.to_s == "disability_60_plus" ? regime.parameter_decimal!("taxpayer_disability_deduction") : BigDecimal("0")
        general_family_deduction = capped_deduction(
          amount: general_family_expenses,
          rate: regime.parameter_decimal!("general_family_deduction_rate"),
          cap: regime.parameter_decimal!("general_family_deduction_cap")
        )
        health_expenses_deduction = capped_deduction(
          amount: health_expenses,
          rate: regime.parameter_decimal!("health_expenses_deduction_rate"),
          cap: regime.parameter_decimal!("health_expenses_deduction_cap")
        )
        education_expenses_deduction = capped_deduction(
          amount: education_expenses,
          rate: regime.parameter_decimal!("education_expenses_deduction_rate"),
          cap: regime.parameter_decimal!("education_expenses_deduction_cap")
        )
        housing_rent_deduction = capped_deduction(
          amount: housing_rent,
          rate: regime.parameter_decimal!("housing_rent_deduction_rate"),
          cap: regime.parameter_decimal!("housing_rent_deduction_cap")
        )
        alimony_deduction = percentage_deduction(
          amount: alimony_paid,
          rate: regime.parameter_decimal!("alimony_deduction_rate")
        )
        care_home_deduction = capped_deduction(
          amount: care_home_expenses,
          rate: regime.parameter_decimal!("care_home_deduction_rate"),
          cap: regime.parameter_decimal!("care_home_deduction_cap")
        )
        domestic_work_deduction = capped_deduction(
          amount: domestic_work_expenses,
          rate: regime.parameter_decimal!("domestic_work_deduction_rate"),
          cap: regime.parameter_decimal!("domestic_work_deduction_cap")
        )

        deductions = {
          dependent_deduction:,
          dependent_under_three_deduction:,
          ascendant_deduction:,
          disability_deduction:,
          general_family_deduction:,
          health_expenses_deduction:,
          education_expenses_deduction:,
          housing_rent_deduction:,
          alimony_deduction:,
          care_home_deduction:,
          domestic_work_deduction:
        }

        deductions.merge(total: deductions.values.sum)
      end

      def self.parse_count(value)
        parsed_value = Integer(value.to_s, exception: false)
        raise ArgumentError if parsed_value.nil? || parsed_value.negative?

        parsed_value
      end

      def self.parse_amount(value)
        parsed_value = BigDecimal(value.to_s)
        raise ArgumentError if parsed_value.negative?

        parsed_value
      rescue ArgumentError
        raise ArgumentError
      end

      def self.capped_deduction(amount:, rate:, cap:)
        [ parse_amount(amount) * rate, cap ].min
      end

      def self.percentage_deduction(amount:, rate:)
        parse_amount(amount) * rate
      end

      def self.validate_count(key, value, errors)
        parse_count(value)
      rescue ArgumentError
        errors << "#{key} must be 0 or greater"
      end
      private_class_method :validate_count

      def self.validate_amount(key, value, errors)
        parse_amount(value)
      rescue ArgumentError
        errors << "#{key} must be 0 or greater"
      end
      private_class_method :validate_amount
    end
  end
end
