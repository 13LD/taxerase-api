module Taxerase
  module Spain2025
    class ProgressiveTax
      def self.call(amount:, brackets:)
        taxable_amount = BigDecimal(amount.to_s)
        return BigDecimal("0") if taxable_amount <= 0

        total = BigDecimal("0")
        lower_bound = BigDecimal("0")

        brackets.each do |upper_bound, rate|
          rate_decimal = BigDecimal(rate.to_s)

          if upper_bound
            upper_amount = BigDecimal(upper_bound.to_s)
            slice = [taxable_amount, upper_amount].min - lower_bound
            total += slice * rate_decimal if slice.positive?
            break if taxable_amount <= upper_amount

            lower_bound = upper_amount
          else
            slice = taxable_amount - lower_bound
            total += slice * rate_decimal if slice.positive?
            break
          end
        end

        total
      end
    end
  end
end
