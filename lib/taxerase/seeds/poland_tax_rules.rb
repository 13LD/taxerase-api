module Taxerase
  module Seeds
    class PolandTaxRules < BaseCountryTaxRules
      tax_rule_data = load_country_tax_data("poland")
      LIVE_YEARS = tax_rule_data.fetch("live_years").freeze
      REGIME_KEYS = tax_rule_data.fetch("regime_keys").freeze
      PIT_SCALE_BRACKETS = tax_rule_data.fetch("pit_scale_brackets").freeze
      YEAR_RULES = year_keyed_hash(tax_rule_data.fetch("year_rules"), symbolize_values: true).freeze
      SOURCE_DEFINITIONS = source_definitions_from(tax_rule_data.fetch("source_definitions")).freeze

      def country_code
        "PL"
      end

      def country_name
        "Poland"
      end

      def currency_code
        "PLN"
      end

      private

      def source_definitions
        SOURCE_DEFINITIONS
      end

      def expected_regime_keys_by_year
        LIVE_YEARS.index_with { REGIME_KEYS }
      end

      def seed_country(country)
        destroy_stale_regimes!(country, categories: %w[employee self_employed], live_years: LIVE_YEARS)

        LIVE_YEARS.each do |tax_year|
          seed_employee_regime(country, tax_year)
          seed_self_employed_regime(country, tax_year)
        end
      end

      def seed_employee_regime(country, tax_year)
        regime = build_regime(
          country:,
          key: "employee_poland",
          name: "Contract of employment - Poland",
          tax_year:,
          category: "employee",
          region: "Poland",
          description: "Employment-contract calculator for Poland with employee payroll deductions, revenue-cost modes, PIT-2 tax relief selection, optional PPK, and employer-cost estimation."
        )

        replace_parameters!(regime, common_parameters_for(tax_year).merge(
          "calculation_method" => Taxerase::Poland::EmployeeCalculator::CALCULATION_METHOD,
          "employee_pension_rate" => 0.0976,
          "employee_disability_rate" => 0.015,
          "employee_sickness_rate" => 0.0245,
          "employee_health_rate" => 0.09,
          "employer_pension_rate" => 0.0976,
          "employer_disability_rate" => 0.065,
          "annual_employee_cost_normal" => 3000,
          "annual_employee_cost_elevated" => 3600,
          "annual_copyright_cost_cap" => 120_000
        ))
        replace_brackets!(regime, "pit_scale", PIT_SCALE_BRACKETS)
        replace_source_usages!(regime, employee_source_usages_for(tax_year))
      end

      def seed_self_employed_regime(country, tax_year)
        regime = build_regime(
          country:,
          key: "self_employed_poland",
          name: "B2B contract - Poland",
          tax_year:,
          category: "self_employed",
          region: "Poland",
          description: "B2B calculator for Poland with tax-scale, flat-tax, and lump-sum paths, ZUS relief modes, optional sickness contribution, and official 2025/2026 health thresholds."
        )

        replace_parameters!(regime, common_parameters_for(tax_year).merge(
          "calculation_method" => Taxerase::Poland::SelfEmployedCalculator::CALCULATION_METHOD,
          "flat_tax_rate" => 0.19,
          "tax_scale_health_rate" => 0.09,
          "flat_tax_health_rate" => 0.049
        ))
        replace_brackets!(regime, "pit_scale", PIT_SCALE_BRACKETS)
        replace_source_usages!(regime, self_employed_source_usages_for(tax_year))
      end

      def common_parameters_for(tax_year)
        year_rules = YEAR_RULES.fetch(tax_year)

        {
          "annual_tax_reducing_amount" => 3600,
          "special_relief_income_cap" => 85_528,
          "child_relief_first_child" => 1112.04,
          "child_relief_second_child" => 1112.04,
          "child_relief_third_child" => 2000.04,
          "child_relief_fourth_plus_child" => 2700,
          "child_relief_one_child_single_income_limit" => 56_000,
          "child_relief_one_child_household_income_limit" => 112_000,
          "lump_sum_rate_professional_services" => 0.17,
          "lump_sum_rate_it_services" => 0.12,
          "lump_sum_rate_healthcare" => 0.14,
          "lump_sum_rate_general_services" => 0.085,
          "lump_sum_rate_manufacturing_construction" => 0.055,
          "lump_sum_rate_trade_gastronomy" => 0.03,
          "zus_pension_rate" => 0.1952,
          "zus_disability_rate" => 0.08,
          "zus_sickness_rate" => 0.0245,
          "zus_accident_rate" => 0.0167,
          "labor_fund_rate" => 0.0245,
          "fgsp_rate" => 0.001,
          "monthly_minimum_wage" => year_rules.fetch(:monthly_minimum_wage),
          "monthly_standard_social_base" => year_rules.fetch(:monthly_standard_social_base),
          "monthly_preferential_social_base" => year_rules.fetch(:monthly_preferential_social_base),
          "monthly_small_zus_plus_min_base" => year_rules.fetch(:monthly_small_zus_plus_min_base),
          "monthly_small_zus_plus_max_base" => year_rules.fetch(:monthly_small_zus_plus_max_base),
          "monthly_general_health_minimum" => year_rules.fetch(:monthly_general_health_minimum),
          "monthly_lump_sum_health_base_low" => year_rules.fetch(:monthly_lump_sum_health_base_low),
          "monthly_lump_sum_health_base_mid" => year_rules.fetch(:monthly_lump_sum_health_base_mid),
          "monthly_lump_sum_health_base_high" => year_rules.fetch(:monthly_lump_sum_health_base_high),
          "lump_sum_health_threshold_low" => 60_000,
          "lump_sum_health_threshold_mid" => 300_000
        }
      end

      def employee_source_usages_for(tax_year)
        [
          { source_key: "pl_#{tax_year}_pit_rates", usage_type: "pit_scale", label: "Podatki.gov.pl: PIT rates" },
          { source_key: "pl_#{tax_year}_employee_costs", usage_type: "employee_costs", label: "Podatki.gov.pl: employee deductible costs" },
          { source_key: "pl_#{tax_year}_child_relief", usage_type: "child_relief", label: "Podatki.gov.pl: child relief" },
          { source_key: "pl_#{tax_year}_relief_for_young", usage_type: "relief_for_young", label: "Podatki.gov.pl: relief for young" },
          { source_key: "pl_#{tax_year}_return_relief", usage_type: "return_relief", label: "Podatki.gov.pl: return relief" },
          { source_key: "pl_#{tax_year}_family_4plus_relief", usage_type: "family_4plus_relief", label: "Podatki.gov.pl: family 4+ relief" },
          { source_key: "pl_#{tax_year}_working_senior_relief", usage_type: "working_senior_relief", label: "Podatki.gov.pl: working senior relief" },
          { source_key: "pl_#{tax_year}_ppk", usage_type: "ppk", label: "MojePPK.pl: PPK contribution rates" },
          { source_key: tax_year == 2026 ? "pl_2026_zus_social_rates" : "pl_2025_zus_social", usage_type: "zus_social_rates", label: "ZUS: social insurance contribution rates" }
        ]
      end

      def self_employed_source_usages_for(tax_year)
        [
          { source_key: "pl_#{tax_year}_pit_rates", usage_type: "pit_scale", label: "Podatki.gov.pl: PIT rates" },
          { source_key: tax_year == 2026 ? "pl_2026_flat_tax" : "pl_2025_pit_scale", usage_type: "flat_tax", label: "Podatki.gov.pl: flat tax" },
          { source_key: tax_year == 2026 ? "pl_2026_lump_sum" : "pl_2025_pit_scale", usage_type: "lump_sum", label: "Podatki.gov.pl: lump sum taxation" },
          { source_key: "pl_#{tax_year}_child_relief", usage_type: "child_relief", label: "Podatki.gov.pl: child relief" },
          { source_key: "pl_#{tax_year}_return_relief", usage_type: "return_relief", label: "Podatki.gov.pl: return relief" },
          { source_key: "pl_#{tax_year}_family_4plus_relief", usage_type: "family_4plus_relief", label: "Podatki.gov.pl: family 4+ relief" },
          { source_key: "pl_#{tax_year}_working_senior_relief", usage_type: "working_senior_relief", label: "Podatki.gov.pl: working senior relief" },
          { source_key: tax_year == 2026 ? "pl_2026_zus_social_rates" : "pl_2025_zus_social", usage_type: "zus_social", label: "ZUS: entrepreneur social contributions" },
          { source_key: "pl_#{tax_year}_zus_health_general", usage_type: "zus_health_general", label: "ZUS: minimum health contribution" },
          { source_key: "pl_#{tax_year}_zus_health_lump_sum", usage_type: "zus_health_lump_sum", label: "ZUS: lump-sum health thresholds" }
        ]
      end
    end
  end
end
