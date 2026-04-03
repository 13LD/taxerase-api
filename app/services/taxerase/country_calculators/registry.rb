module Taxerase
  module CountryCalculators
    class Registry
      class UnavailableCountryError < KeyError; end

      DEFAULT_COUNTRY_CODE = "ES".freeze

      DEFINITIONS = {
        "ES" => SpainDefinition.new,
        "NL" => NetherlandsDefinition.new,
        "PL" => PolandDefinition.new,
        "CZ" => CzechRepublicDefinition.new,
        "PT" => PortugalDefinition.new,
        "AD" => AndorraDefinition.new
      }.freeze

      def self.default
        fetch(DEFAULT_COUNTRY_CODE)
      end

      def self.default_available
        definition = fetch(DEFAULT_COUNTRY_CODE)
        return definition if definition.available?

        available_definitions.first || raise(
          UnavailableCountryError,
          "No country calculator seed data is available. Run db:seed."
        )
      end

      def self.fetch(country_code)
        DEFINITIONS.fetch(country_code.to_s.upcase)
      rescue KeyError
        raise KeyError, "No country calculator is registered for #{country_code.inspect}."
      end

      def self.fetch_available(country_code)
        definition = fetch(country_code)
        return definition if definition.available?

        raise UnavailableCountryError, "#{definition.country.fetch(:name)} calculator data is not available. Run db:seed."
      end

      def self.home_definition(country_code)
        fetch_available(country_code.presence || DEFAULT_COUNTRY_CODE)
      rescue KeyError, UnavailableCountryError
        default_available
      end

      def self.available_definitions
        DEFINITIONS.values.select(&:available?)
      end

      def self.country_options
        available_definitions.map(&:country)
      end

      def self.comparison_catalog
        available_definitions.map(&:public_catalog)
      end

      def self.comparison_profile_catalog
        available_definitions
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
