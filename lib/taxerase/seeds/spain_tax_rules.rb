module Taxerase
  module Seeds
    class SpainTaxRules
      SPECIAL_INBOUND_WORKER_BRACKETS = [
        [ 600_000, 0.24 ],
        [ nil, 0.47 ]
      ].freeze

      COMPANY_BRACKETS = [
        [ nil, 0.25 ]
      ].freeze

      def self.call
        new.call
      end

      def call
        ActiveRecord::Base.transaction do
          spain = Country.find_or_initialize_by(code: "ES")
          spain.update!(name: "Spain", currency_code: "EUR")

          purge_obsolete_live_regimes!(spain)
          seed_live_regimes(spain)
          seed_company_regime(spain)
          seed_inbound_workers_regime(spain)
        end
      end

      private

      def purge_obsolete_live_regimes!(country)
        expected_keys = Taxerase::Spain2025::RegionCatalog::COMMON_REGIME_REGIONS.flat_map do |region|
          [
            regime_key_for("employee", region[:key]),
            regime_key_for("self_employed", region[:key])
          ]
        end

        country.tax_regimes
          .where(tax_year: 2025, category: %w[employee self_employed])
          .where.not(key: expected_keys)
          .find_each(&:destroy!)
      end

      def seed_live_regimes(country)
        Taxerase::Spain2025::RegionCatalog::COMMON_REGIME_REGIONS.each do |region|
          seed_employee_regime(country, region)
          seed_self_employed_regime(country, region)
        end
      end

      def seed_employee_regime(country, region_config)
        regime = build_regime(
          country:,
          key: regime_key_for("employee", region_config[:key]),
          name: "Resident employee - #{region_config[:name]}",
          tax_year: 2025,
          category: "employee",
          region: region_config[:name],
          description: "Resident salaried employee in #{region_config[:name]} under the general IRPF regime."
        )

        replace_parameters!(
          regime,
          {
            "gross_work_income_deduction" => 2000,
            "state_taxpayer_minimum" => Taxerase::Spain2025::RegionCatalog::STATE_TAXPAYER_MINIMUM,
            "regional_taxpayer_minimum" => region_config[:regional_taxpayer_minimum],
            "monthly_min_contribution_base" => 1381.20,
            "monthly_max_contribution_base" => 4909.50,
            "employee_social_security_rate" => 0.0648,
            "low_income_deduction_max" => 340,
            "low_income_deduction_full_threshold" => 16_576,
            "low_income_deduction_phase_out_threshold" => 18_276,
            "low_income_deduction_phase_out_rate" => 0.2
          }
        )

        replace_brackets!(regime, "state_irpf", Taxerase::Spain2025::RegionCatalog::STATE_IRPF_BRACKETS)
        replace_brackets!(regime, "regional_irpf", region_config[:regional_brackets])
      end

      def seed_self_employed_regime(country, region_config)
        regime = build_regime(
          country:,
          key: regime_key_for("self_employed", region_config[:key]),
          name: "Resident self-employed - #{region_config[:name]}",
          tax_year: 2025,
          category: "self_employed",
          region: region_config[:name],
          description: "Resident self-employed person in #{region_config[:name]} under direct estimation simplified."
        )

        replace_parameters!(
          regime,
          {
            "state_taxpayer_minimum" => Taxerase::Spain2025::RegionCatalog::STATE_TAXPAYER_MINIMUM,
            "regional_taxpayer_minimum" => region_config[:regional_taxpayer_minimum],
            "self_employed_social_security_rate" => 0.314,
            "self_employed_social_security_generic_expense_rate" => 0.07,
            "difficult_to_justify_deduction_rate" => 0.05,
            "difficult_to_justify_deduction_cap" => 2000
          }
        )

        replace_brackets!(regime, "state_irpf", Taxerase::Spain2025::RegionCatalog::STATE_IRPF_BRACKETS)
        replace_brackets!(regime, "regional_irpf", region_config[:regional_brackets])
        replace_range_brackets!(regime, "self_employed_social_security_bands", Taxerase::Spain2025::RegionCatalog::RETA_2025_BANDS)
      end

      def regime_key_for(category, region_key)
        Taxerase::Spain2025::RegionCatalog.regime_key(category:, region_key:)
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

      def seed_company_regime(country)
        regime = build_regime(
          country:,
          key: "corporate_income_general",
          name: "Corporate income tax - general",
          tax_year: 2025,
          category: "company",
          region: "Spain",
          description: "General corporate income tax rate."
        )

        replace_brackets!(regime, "corporate_income", COMPANY_BRACKETS)
      end

      def seed_inbound_workers_regime(country)
        regime = build_regime(
          country:,
          key: "inbound_workers_article_93",
          name: "Inbound workers regime - article 93",
          tax_year: 2025,
          category: "special_regime",
          region: "Spain",
          description: "Special regime applicable to workers displaced to Spain."
        )

        replace_brackets!(regime, "employment_income", SPECIAL_INBOUND_WORKER_BRACKETS)
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

      def replace_parameters!(regime, values)
        regime.tax_parameters.delete_all

        values.each do |key, value|
          regime.tax_parameters.create!(
            key:,
            value_decimal: value
          )
        end
      end
    end
  end
end
