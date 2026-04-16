module Taxerase
  module Support
    module CountryRouter
      def default_regime_key(tax_year)
        TaxRegime.default_supported_key_for(
          country:,
          tax_year:,
          supported_methods: supported_method_keys
        )
      end

      def regime_options(catalog_options = nil)
        return TaxRegime.public_regime_options_for(country:, catalog_options:) if catalog_options

        TaxRegime
          .for_country(country)
          .includes(:tax_parameters, tax_source_usages: :official_tax_source)
          .ordered_for_catalog
          .map { |regime| build_regime_option_payload(regime) }
      end

      def public_regime_options(catalog_options = nil)
        regime_options(catalog_options || public_catalog_regime_options)
      end

      def public_catalog_regime_options
        TaxRegime.public_catalog_options_for(country:, supported_methods: supported_method_keys)
      end

      def public_catalog_data
        TaxRegime.public_catalog_data_for(country:, supported_methods: supported_method_keys)
      end

      def public_regime_categories
        TaxRegime.supported_categories_for(country:, supported_methods: supported_method_keys)
      end

      def public_tax_year_options
        TaxRegime.supported_tax_years_for(country:, supported_methods: supported_method_keys)
      end

      def supported?(regime_or_key, tax_year = nil)
        regime = regime_or_key.is_a?(TaxRegime) ? regime_or_key : find_regime(regime_or_key, tax_year)

        regime.present? &&
          regime.country_id == country.id &&
          supported_method_keys.include?(regime.parameter_text("calculation_method"))
      end

      def regime_for!(regime_key, tax_year)
        find_regime(regime_key, tax_year) || raise(
          UnsupportedRegimeError.new([ "#{regime_key} is not available for #{country_name_in_errors} #{tax_year}." ])
        )
      end

      def find_regime(regime_key, tax_year)
        TaxRegime
          .with_routing_data
          .for_country_year(country:, tax_year:)
          .find_by(key: regime_key)
      end

      def unsupported_message_for(regime)
        if source_backed_unsupported_message? && regime.official_tax_sources.any?
          "#{regime.name} has official sources linked for #{regime.tax_year}, but its calculator flow is not implemented yet."
        else
          "#{regime.name} is stored in the rules database, but its calculator flow is not implemented yet."
        end
      end

      def country
        @country ||= Country.find_by!(code: self::COUNTRY_CODE)
      end

      def input_currency_handler
        @input_currency_handler ||= Taxerase::InputCurrencyHandler.new(
          native_currency_code: self::NATIVE_CURRENCY_CODE,
          supported_currency_codes: self::SUPPORTED_INPUT_CURRENCY_CODES
        )
      end

      private

      def build_regime_option_payload(regime)
        supported = supported?(regime)

        {
          key: regime.key,
          name: regime.name,
          region: regime.region,
          category: regime.category,
          tax_year: regime.tax_year,
          description: regime.description,
          supported: supported,
          status: supported ? "Live" : "Research",
          sources: regime.source_links
        }
      end

      def supported_method_keys
        self::SUPPORTED_METHODS.keys
      end

      def country_name_in_errors
        country.name
      end

      def source_backed_unsupported_message?
        false
      end
    end
  end
end
