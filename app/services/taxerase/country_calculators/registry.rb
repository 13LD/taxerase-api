module Taxerase
  module CountryCalculators
    class Registry
      DEFAULT_COUNTRY_CODE = "ES".freeze

      DEFINITIONS = {
        "ES" => SpainDefinition.new,
        "NL" => NetherlandsDefinition.new
      }.freeze

      def self.default
        fetch(DEFAULT_COUNTRY_CODE)
      end

      def self.fetch(country_code)
        DEFINITIONS.fetch(country_code.to_s.upcase)
      rescue KeyError
        raise KeyError, "No country calculator is registered for #{country_code.inspect}."
      end

      def self.country_options
        DEFINITIONS.values.map(&:country)
      end

      def self.comparison_catalog
        DEFINITIONS.values.map(&:public_catalog)
      end
    end
  end
end
