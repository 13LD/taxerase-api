module Taxerase
  module CountryCalculators
    class Registry
      DEFAULT_COUNTRY_CODE = "ES".freeze

      DEFINITIONS = {
        "ES" => SpainDefinition.new,
        "NL" => NetherlandsDefinition.new,
        "PL" => PolandDefinition.new,
        "CZ" => CzechRepublicDefinition.new
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

      def self.comparison_profile_catalog
        DEFINITIONS.values
          .flat_map(&:public_comparison_profiles)
          .uniq { |profile| profile.fetch(:key) }
      end

      def self.fetch_comparison_profile(profile_key)
        comparison_profile_catalog.find { |profile| profile.fetch(:key) == profile_key.to_s } ||
          raise(KeyError, "No comparison profile is registered for #{profile_key.inspect}.")
      end
    end
  end
end
