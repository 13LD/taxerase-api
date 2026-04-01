module Taxerase
  module Netherlands
    class FormulaBrackets
      def self.call(regime:, bracket_group:, amount:)
        bracket = regime.bracket_for_amount(bracket_group, amount) || regime.bracket_records_for(bracket_group).last
        raise KeyError, "Missing bracket formula #{bracket_group} for #{regime.key}" unless bracket

        amount_decimal = BigDecimal(amount.to_s)
        lower_bound = bracket.lower_bound&.to_d || BigDecimal("0")
        base_amount = bracket.base_min&.to_d || BigDecimal("0")
        rate = bracket.rate&.to_d || BigDecimal("0")

        [ base_amount + ([ amount_decimal - lower_bound, 0 ].max * rate), 0 ].max
      end
    end
  end
end
