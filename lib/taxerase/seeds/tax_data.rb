module Taxerase
  module Seeds
    class TaxData
      SEEDERS = [
        AndorraTaxRules,
        SpainTaxRules,
        NetherlandsTaxRules,
        PolandTaxRules,
        CzechRepublicTaxRules,
        PortugalTaxRules
      ].freeze

      def self.call
        SEEDERS.each(&:call)
      end
    end
  end
end
