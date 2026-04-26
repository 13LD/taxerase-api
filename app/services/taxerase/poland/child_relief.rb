module Taxerase
  module Poland
    class ChildRelief
      CHILD_RELIEF_KEYS = {
        1 => "child_relief_first_child",
        2 => "child_relief_second_child",
        3 => "child_relief_third_child",
        4 => "child_relief_fourth_plus_child"
      }.freeze

      def self.call(
        regime:,
        children_count:,
        household_income:,
        household_status: "single",
        claim_share: 100
      )
        parsed_children_count = Integer(children_count.to_s, exception: false) || 0
        return BigDecimal("0") if parsed_children_count <= 0
        return BigDecimal("0") if parsed_children_count == 1 && above_one_child_income_threshold?(
          regime:,
          household_status:,
          household_income:
        )

        relief = (1..parsed_children_count).sum do |child_index|
          key = CHILD_RELIEF_KEYS.fetch([ child_index, 4 ].min)
          regime.parameter_decimal!(key)
        end

        relief * claim_share_decimal(claim_share)
      end

      def self.above_one_child_income_threshold?(regime:, household_status:, household_income:)
        threshold_key = household_status.to_s == "single" ? "child_relief_one_child_single_income_limit" : "child_relief_one_child_household_income_limit"
        BigDecimal(household_income.to_s) > regime.parameter_decimal!(threshold_key)
      rescue ArgumentError
        false
      end
      private_class_method :above_one_child_income_threshold?

      def self.claim_share_decimal(value)
        parsed_value = BigDecimal(value.to_s)
        return BigDecimal("0") if parsed_value.negative?
        return BigDecimal("1") if parsed_value > 100

        parsed_value / 100
      rescue ArgumentError
        BigDecimal("1")
      end
      private_class_method :claim_share_decimal
    end
  end
end
