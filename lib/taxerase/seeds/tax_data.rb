module Taxerase
  module Seeds
    class TaxData
      SEEDERS = [
        SpainTaxRules,
        NetherlandsTaxRules,
        PolandTaxRules,
        CzechRepublicTaxRules
      ].freeze

      def self.call
        SEEDERS.each(&:call)
      end
    end
  end
end
