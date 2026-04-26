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
        apply_working_senior_relief: false,
        apply_return_relief: false,
        return_relief_prior_non_resident: false,
        return_relief_year: 0,
        working_senior_receives_pension: false,
        young_worker_relief_income_type: "employment"
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
        if truthy?(apply_working_senior_relief) && truthy?(working_senior_receives_pension)
          errors << "working senior relief requires not receiving a pension"
        end
        if truthy?(apply_return_relief)
          parsed_return_relief_year = Integer(return_relief_year.to_s, exception: false)
          errors << "return relief requires prior non-residence eligibility" unless truthy?(return_relief_prior_non_resident)
          errors << "return_relief_year must be between 1 and 4" unless (1..4).include?(parsed_return_relief_year)
        end
        unless %w[employment other].include?(young_worker_relief_income_type.to_s)
          errors << "young_worker_relief_income_type must be one of: employment, other"
        end

        errors
      end

      def self.call(
        regime:,
        age_bracket:,
        apply_return_relief: false,
        apply_family_4plus_relief: false,
        apply_working_senior_relief: false,
        allow_relief_for_young: true,
        young_worker_eligible: false
      )
        enabled_reliefs = []
        if allow_relief_for_young && young_worker_eligible
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
