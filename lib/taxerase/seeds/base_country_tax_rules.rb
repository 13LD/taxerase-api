module Taxerase
  module Seeds
    class BaseCountryTaxRules
      def self.call
        new.call
      end

      def call
        ActiveRecord::Base.transaction do
          country = Country.find_or_initialize_by(code: country_code)
          country.update!(name: country_name, currency_code: currency_code)

          seed_country(country)
          verify_country_data!(country)
        end
      end

      private

      def currency_code
        "EUR"
      end

      def seed_country(_country)
        raise NotImplementedError, "#{self.class.name} must implement #seed_country"
      end

      def source_definitions
        raise NotImplementedError, "#{self.class.name} must implement #source_definitions"
      end

      def expected_regime_keys_by_year
        raise NotImplementedError, "#{self.class.name} must implement #expected_regime_keys_by_year"
      end

      def verify_country_data!(country)
        verify_regime_country_links!(country)
        verify_source_country_links!(country)
      end

      def verify_regime_country_links!(country)
        expected_regime_keys_by_year.each do |tax_year, keys|
          next if keys.empty?

          mismatched_regimes = TaxRegime.where(key: keys, tax_year: tax_year).where.not(country_id: country.id)
          next unless mismatched_regimes.exists?

          raise "#{country.code} seed integrity check failed for #{tax_year}: #{mismatched_regimes.pluck(:key).join(', ')}"
        end
      end

      def verify_source_country_links!(country)
        mismatched_source_usage = TaxSourceUsage
          .joins(:tax_regime, :official_tax_source)
          .where(tax_regimes: { country_id: country.id })
          .where.not(official_tax_sources: { country_code: country.code })

        return unless mismatched_source_usage.exists?

        raise "#{country.code} source integrity check failed: linked sources have a different country code"
      end

      def build_regime(country:, key:, name:, tax_year:, category:, region:, description:)
        regime = TaxRegime.find_or_initialize_by(country:, key:, tax_year:)
        regime.update!(
          name:,
          category:,
          region:,
          active: true,
          description:
        )
        regime
      end

      def replace_brackets!(regime, group, rows)
        regime.tax_brackets.where(bracket_group: group).delete_all

        rows.each_with_index do |(upper_bound, rate), index|
          regime.tax_brackets.create!(
            bracket_group: group,
            position: index + 1,
            upper_bound:,
            rate:
          )
        end
      end

      def replace_formula_brackets!(regime, group, rows)
        regime.tax_brackets.where(bracket_group: group).delete_all

        rows.each_with_index do |row, index|
          regime.tax_brackets.create!(
            bracket_group: group,
            position: index + 1,
            lower_bound: row[:lower_bound],
            upper_bound: row[:upper_bound],
            base_min: row[:base_min],
            rate: row[:rate],
            label: row[:label]
          )
        end
      end

      def replace_range_brackets!(regime, group, rows)
        regime.tax_brackets.where(bracket_group: group).delete_all

        rows.each_with_index do |row, index|
          regime.tax_brackets.create!(
            bracket_group: group,
            position: index + 1,
            lower_bound: row[:lower_bound],
            upper_bound: row[:upper_bound],
            base_min: row[:base_min],
            base_max: row[:base_max],
            label: row[:label]
          )
        end
      end

      def replace_parameters!(regime, values)
        regime.tax_parameters.delete_all

        values.each do |key, value|
          if value.is_a?(String)
            regime.tax_parameters.create!(key:, value_text: value)
          else
            regime.tax_parameters.create!(key:, value_decimal: value)
          end
        end
      end

      def replace_source_usages!(regime, usages)
        regime.tax_source_usages.delete_all

        usages.each_with_index do |usage, index|
          regime.tax_source_usages.create!(
            official_tax_source: source_for!(usage[:source_key]),
            usage_type: usage[:usage_type],
            label: usage[:label],
            notes: usage[:notes],
            position: index + 1
          )
        end
      end

      def source_for!(key)
        definition = source_definitions.fetch(key)
        source = OfficialTaxSource.find_or_initialize_by(key: key)
        source.update!(definition)
        source
      end
    end
  end
end
