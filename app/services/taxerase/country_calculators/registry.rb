module Taxerase
  module CountryCalculators
    class Registry
      DEFAULT_COUNTRY_CODE = "ES".freeze

      DEFINITIONS = {
        "ES" => SpainDefinition.new
      }.freeze

      def self.default
        fetch(DEFAULT_COUNTRY_CODE)
      end

      def self.fetch(country_code)
        DEFINITIONS.fetch(country_code.to_s.upcase)
      rescue KeyError
        raise KeyError, "No country calculator is registered for #{country_code.inspect}."
      end
    end
  end
end
