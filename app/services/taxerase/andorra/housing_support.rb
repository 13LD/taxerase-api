module Taxerase
  module Andorra
    module HousingSupport
      BOOLEAN_VALUES = [ true, false, "true", "false", "1", "0", 1, 0, nil, "" ].freeze

      def self.validation_errors(
        apply_housing_rent_support:,
        housing_support_priority_group:,
        housing_rent:
      )
        errors = []
        errors << "apply_housing_rent_support must be true or false" unless BOOLEAN_VALUES.include?(apply_housing_rent_support)
        errors << "housing_support_priority_group must be true or false" unless BOOLEAN_VALUES.include?(housing_support_priority_group)
        errors << "housing_rent must be 0 or greater" if parse_amount(housing_rent).negative?
        errors
      end

      def self.estimate(
        annual_housing_rent:,
        apply_housing_rent_support:,
        housing_support_priority_group:,
        parameter_decimal:
      )
        annual_rent = parse_amount(annual_housing_rent)
        return empty_result unless boolean_value?(apply_housing_rent_support) && annual_rent.positive?

        rate =
          if boolean_value?(housing_support_priority_group)
            parameter_decimal.call("housing_rent_support_priority_rate")
          else
            parameter_decimal.call("housing_rent_support_standard_rate")
          end

        {
          annual_housing_rent: annual_rent,
          support_rate: rate,
          annual_support_estimate: annual_rent * rate,
          priority_group: boolean_value?(housing_support_priority_group)
        }
      end

      def self.empty_result
        {
          annual_housing_rent: BigDecimal("0"),
          support_rate: BigDecimal("0"),
          annual_support_estimate: BigDecimal("0"),
          priority_group: false
        }
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
