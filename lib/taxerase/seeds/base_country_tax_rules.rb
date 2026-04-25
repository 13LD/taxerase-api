require "json"

module Taxerase
  module Seeds
    class BaseCountryTaxRules
      def self.load_country_tax_data(country_key)
        JSON.parse(File.read(File.join(__dir__, "countries", country_key, "tax_rules.json")))
      end

      def self.year_keyed_hash(values, symbolize_values: false)
        values.to_h do |year, value|
          normalized_value = symbolize_values ? deep_symbolize_keys(value) : value
          [ Integer(year), normalized_value ]
        end
      end

      def self.source_definitions_from(values)
        values.transform_values { |attributes| deep_symbolize_keys(attributes) }
      end

      def self.deep_symbolize_keys(value)
        case value
        when Array
          value.map { |entry| deep_symbolize_keys(entry) }
        when Hash
          value.to_h { |key, entry| [ key.to_sym, deep_symbolize_keys(entry) ] }
        else
          value
        end
      end
      private_class_method :load_country_tax_data,
        :year_keyed_hash,
        :source_definitions_from,
        :deep_symbolize_keys

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

          mismatched_regimes = TaxRegime
            .for_tax_year(tax_year)
            .where(key: keys)
            .where.not(tax_rule_sets: { country_id: country.id })
          next unless mismatched_regimes.exists?

          raise "#{country.code} seed integrity check failed for #{tax_year}: #{mismatched_regimes.pluck(:key).join(', ')}"
        end
      end

      def verify_source_country_links!(country)
        mismatched_source_usage = TaxSourceUsage
          .joins(tax_regime: :tax_rule_set)
          .joins(:official_tax_source)
          .where(tax_rule_sets: { country_id: country.id })
          .where.not(official_tax_sources: { country_id: country.id })

        return unless mismatched_source_usage.exists?

        raise "#{country.code} source integrity check failed: linked sources have a different country code"
      end

      def build_regime(country:, key:, name:, tax_year:, category:, region:, description:)
        rule_set = build_rule_set(country:, tax_year:)
        regime = TaxRegime.find_or_initialize_by(tax_rule_set: rule_set, key:)
        regime.update!(
          name:,
          category:,
          region:,
          active: true,
          description:
        )
        regime
      end

      def build_rule_set(country:, tax_year:)
        rule_set = TaxRuleSet.find_or_initialize_by(
          country:,
          tax_year:,
          key: rule_set_key(tax_year)
        )
        rule_set.update!(
          name: "#{country.name} #{tax_year} seeded tax rules",
          release_version: rule_set_release_version(tax_year),
          status: "published",
          active: true
        )
        rule_set
      end

      def rule_set_key(_tax_year)
        "default"
      end

      def rule_set_release_version(_tax_year)
        "seeded-v1"
      end

      def destroy_stale_regimes!(country, categories:, live_years:)
        TaxRegime
          .for_country(country)
          .where(category: categories)
          .where.not(tax_rule_sets: { tax_year: live_years })
          .find_each(&:destroy!)
      end

      def replace_brackets!(regime, group, rows)
        TaxBracket.where(tax_regime_id: regime.id, bracket_group: group).delete_all
        regime.association(:tax_brackets).reset
        timestamp = Time.current

        TaxBracket.upsert_all(
          rows.each_with_index.map do |(upper_bound, rate), index|
            {
              tax_regime_id: regime.id,
              bracket_group: group,
              position: index + 1,
              upper_bound:,
              rate:,
              created_at: timestamp,
              updated_at: timestamp
            }
          end,
          unique_by: :idx_on_tax_regime_id_bracket_group_position_e563c89903
        )
      end

      def replace_formula_brackets!(regime, group, rows)
        TaxBracket.where(tax_regime_id: regime.id, bracket_group: group).delete_all
        regime.association(:tax_brackets).reset
        timestamp = Time.current

        TaxBracket.upsert_all(
          rows.each_with_index.map do |row, index|
            {
              tax_regime_id: regime.id,
              bracket_group: group,
              position: index + 1,
              lower_bound: row[:lower_bound],
              upper_bound: row[:upper_bound],
              base_min: row[:base_min],
              rate: row[:rate],
              label: row[:label],
              created_at: timestamp,
              updated_at: timestamp
            }
          end,
          unique_by: :idx_on_tax_regime_id_bracket_group_position_e563c89903
        )
      end

      def replace_range_brackets!(regime, group, rows)
        TaxBracket.where(tax_regime_id: regime.id, bracket_group: group).delete_all
        regime.association(:tax_brackets).reset
        timestamp = Time.current

        TaxBracket.upsert_all(
          rows.each_with_index.map do |row, index|
            {
              tax_regime_id: regime.id,
              bracket_group: group,
              position: index + 1,
              lower_bound: row[:lower_bound],
              upper_bound: row[:upper_bound],
              base_min: row[:base_min],
              base_max: row[:base_max],
              label: row[:label],
              created_at: timestamp,
              updated_at: timestamp
            }
          end,
          unique_by: :idx_on_tax_regime_id_bracket_group_position_e563c89903
        )
      end

      def replace_parameters!(regime, values)
        TaxParameter.where(tax_regime_id: regime.id).delete_all
        regime.association(:tax_parameters).reset
        timestamp = Time.current

        TaxParameter.upsert_all(
          values.map do |key, value|
            {
              tax_regime_id: regime.id,
              key:,
              value_decimal: value.is_a?(String) ? nil : value,
              value_text: value.is_a?(String) ? value : nil,
              created_at: timestamp,
              updated_at: timestamp
            }
          end,
          unique_by: :index_tax_parameters_on_tax_regime_id_and_key
        )
      end

      def replace_source_usages!(regime, usages)
        TaxSourceUsage.where(tax_regime_id: regime.id).delete_all
        regime.association(:tax_source_usages).reset
        timestamp = Time.current

        TaxSourceUsage.upsert_all(
          usages.each_with_index.map do |usage, index|
            {
              tax_regime_id: regime.id,
              official_tax_source_id: source_for!(usage[:source_key]).id,
              usage_type: usage[:usage_type],
              label: usage[:label],
              notes: usage[:notes],
              position: index + 1,
              created_at: timestamp,
              updated_at: timestamp
            }
          end,
          unique_by: :idx_tax_source_usages_unique_link
        )
      end

      def source_for!(key)
        definition = source_definitions.fetch(key).dup
        source_country_code = definition.delete(:country_code) || country_code
        source_country = Country.find_by!(code: source_country_code)
        source = OfficialTaxSource.find_or_initialize_by(key: key)
        source.update!(definition.merge(country: source_country))
        source
      end
    end
  end
end
