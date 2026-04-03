module Taxerase
  module Andorra
    module IncomeTax
      def self.call(net_taxable_income:, personal_minimum:, family_reduction:, regime:)
        flat_rate = regime.parameter_decimal!("irpf_rate")
        taxable_income_before_family_reduction = [ net_taxable_income - personal_minimum, BigDecimal("0") ].max
        taxable_income = [ taxable_income_before_family_reduction - family_reduction, BigDecimal("0") ].max
        annual_income_tax_before_bonus = taxable_income * flat_rate

        {
          taxable_income_before_family_reduction:,
          taxable_income:,
          annual_income_tax_before_bonus:
        }
      end
    end
  end
end
