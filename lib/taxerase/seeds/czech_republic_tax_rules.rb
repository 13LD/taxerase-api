module Taxerase
  module Seeds
    class CzechRepublicTaxRules < BaseCountryTaxRules
      tax_rule_data = load_country_tax_data("czech_republic")
      LIVE_YEARS = tax_rule_data.fetch("live_years").freeze
      REGIME_KEYS = tax_rule_data.fetch("regime_keys").freeze
      INCOME_TAX_BRACKETS = tax_rule_data.fetch("income_tax_brackets").freeze
      SOURCE_DEFINITIONS = source_definitions_from(tax_rule_data.fetch("source_definitions")).freeze

      def country_code
        "CZ"
      end

      def country_name
        "Czech Republic"
      end

      def currency_code
        "CZK"
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

      def common_tax_parameters
        {
          "taxpayer_credit" => 30_840,
          "child_credit_first_child" => 15_204,
          "child_credit_second_child" => 22_320,
          "child_credit_third_plus_child" => 27_840,
          "annual_child_tax_bonus_income_threshold" => 124_800,
          "annual_child_tax_bonus_minimum" => 100,
          "disability_credit_first_or_second_degree" => 2520,
          "disability_credit_third_degree" => 5040,
          "disability_credit_ztp_p" => 16_140
        }
      end

      def seed_employee_regime(country, tax_year)
        regime = build_regime(
          country:,
          key: "employee_czech_republic",
          name: "Resident employee - Czech Republic",
          tax_year:,
          category: "employee",
          region: "Czech Republic",
          description: "Resident employee with Czech income tax, employee social security, public health insurance, and standard taxpayer credits."
        )

        replace_parameters!(regime, common_tax_parameters.merge(
          "calculation_method" => Taxerase::CzechRepublic::EmployeeCalculator::CALCULATION_METHOD,
          "annual_max_social_assessment_base" => 2_234_736,
          "employee_social_security_rate" => 0.071,
          "employee_health_contribution_rate" => 0.045
        ))
        replace_brackets!(regime, "income_tax", INCOME_TAX_BRACKETS)
        replace_source_usages!(regime, [
          { source_key: "cz_2025_income_tax", usage_type: "income_tax", label: "Finanční správa: personal income tax updates 2025" },
          { source_key: "cz_2025_social_insurance", usage_type: "social_insurance", label: "MPSV: social insurance 2025" },
          { source_key: "cz_2025_employee_health", usage_type: "health_insurance", label: "VZP: employee health insurance" }
        ])
      end

      def seed_self_employed_regime(country, tax_year)
        regime = build_regime(
          country:,
          key: "self_employed_czech_republic",
          name: "Resident self-employed - Czech Republic",
          tax_year:,
          category: "self_employed",
          region: "Czech Republic",
          description: "Resident self-employed person using actual deductible expenses with Czech income tax, social security, public health insurance, and standard taxpayer credits."
        )

        replace_parameters!(regime, common_tax_parameters.merge(
          "calculation_method" => Taxerase::CzechRepublic::SelfEmployedCalculator::CALCULATION_METHOD,
          "annual_max_social_assessment_base" => 2_234_736,
          "flat_expense_rate_60" => 0.60,
          "flat_expense_cap_60" => 1_200_000,
          "social_assessment_base_rate" => 0.55,
          "social_contribution_rate" => 0.292,
          "annual_min_social_contribution" => 57_108,
          "health_assessment_base_rate" => 0.50,
          "health_contribution_rate" => 0.135,
          "annual_min_health_contribution" => 37_716
        ))
        replace_brackets!(regime, "income_tax", INCOME_TAX_BRACKETS)
        replace_source_usages!(regime, [
          { source_key: "cz_2025_income_tax", usage_type: "income_tax", label: "Finanční správa: personal income tax updates 2025" },
          { source_key: "cz_2025_entrepreneur_tax", usage_type: "entrepreneur_tax", label: "Finanční správa: entrepreneur tax page" },
          { source_key: "cz_2025_osvc_social", usage_type: "osvc_social", label: "ČSSZ: OSVČ pension insurance advances" },
          { source_key: "cz_2025_osvc_health_base", usage_type: "osvc_health_base", label: "VZP: OSVČ health contribution base" },
          { source_key: "cz_2025_osvc_health_advance", usage_type: "osvc_health_advance", label: "VZP: OSVČ health advances" }
        ])
      end
    end
  end
end
