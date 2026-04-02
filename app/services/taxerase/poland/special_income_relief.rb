module Taxerase
  module Poland
    class SpecialIncomeRelief
      AGE_BRACKETS = %w[under_26 age_26_to_retirement retirement_age_or_older].freeze

      def self.validation_errors(age_bracket:)
        validation_errors_for(
          age_bracket:,
          children_count: 0,
          apply_family_4plus_relief: false,
          apply_working_senior_relief: false
        )
      end

      def self.validation_errors_for(
        age_bracket:,
        children_count:,
        apply_family_4plus_relief: false,
        apply_working_senior_relief: false
      )
        errors = []
        errors << "age_bracket must be one of: #{AGE_BRACKETS.join(', ')}" unless AGE_BRACKETS.include?(age_bracket.to_s)

        parsed_children_count = Integer(children_count.to_s, exception: false)
        if truthy?(apply_family_4plus_relief) && parsed_children_count.to_i < 4
          errors << "family 4+ relief requires at least 4 children"
        end

        if truthy?(apply_working_senior_relief) && age_bracket.to_s != "retirement_age_or_older"
          errors << "working senior relief requires retirement age or older"
        end

        errors
      end

      def self.call(
        regime:,
        age_bracket:,
        apply_return_relief: false,
        apply_family_4plus_relief: false,
        apply_working_senior_relief: false,
        allow_relief_for_young: true
      )
        enabled_reliefs = []
        if allow_relief_for_young && age_bracket.to_s == "under_26"
          enabled_reliefs << "Relief for young people under 26"
        end
        enabled_reliefs << "Return relief" if truthy?(apply_return_relief)
        enabled_reliefs << "Family 4+ relief" if truthy?(apply_family_4plus_relief)
        enabled_reliefs << "Working senior relief" if truthy?(apply_working_senior_relief)

        {
          enabled_reliefs:,
          exempt_income_cap: enabled_reliefs.any? ? regime.parameter_decimal!("special_relief_income_cap") : BigDecimal("0")
        }
      end

      def self.truthy?(value)
        ActiveModel::Type::Boolean.new.cast(value)
      end
    end
  end
end
