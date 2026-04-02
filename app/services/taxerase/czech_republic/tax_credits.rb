module Taxerase
  module CzechRepublic
    class TaxCredits
      DISABILITY_LEVELS = %w[
        none
        invalidity_first_or_second_degree
        invalidity_third_degree
        ztp_p
      ].freeze

      def self.validation_errors(disability_level:)
        return [] if DISABILITY_LEVELS.include?(disability_level.to_s)

        [ "disability_level must be one of: #{DISABILITY_LEVELS.join(', ')}" ]
      end

      def self.child_credit(regime:, children_count:)
        parsed_children_count = Integer(children_count.to_s, exception: false) || 0
        return BigDecimal("0") if parsed_children_count <= 0

        total = BigDecimal("0")
        total += regime.parameter_decimal!("child_credit_first_child") if parsed_children_count >= 1
        total += regime.parameter_decimal!("child_credit_second_child") if parsed_children_count >= 2
        total += [ parsed_children_count - 2, 0 ].max * regime.parameter_decimal!("child_credit_third_plus_child")
        total
      end

      def self.disability_credit(regime:, disability_level:)
        case disability_level.to_s
        when "invalidity_first_or_second_degree"
          regime.parameter_decimal!("disability_credit_first_or_second_degree")
        when "invalidity_third_degree"
          regime.parameter_decimal!("disability_credit_third_degree")
        when "ztp_p"
          regime.parameter_decimal!("disability_credit_ztp_p")
        else
          BigDecimal("0")
        end
      end

      def self.child_tax_bonus(regime:, annual_qualifying_income:, child_credit:, tax_after_standard_credits:)
        raw_bonus = BigDecimal(child_credit.to_s) - BigDecimal(tax_after_standard_credits.to_s)
        return BigDecimal("0") unless raw_bonus.positive?
        return BigDecimal("0") if BigDecimal(annual_qualifying_income.to_s) < regime.parameter_decimal!("annual_child_tax_bonus_income_threshold")
        return BigDecimal("0") if raw_bonus < regime.parameter_decimal!("annual_child_tax_bonus_minimum")

        raw_bonus
      end
    end
  end
end
