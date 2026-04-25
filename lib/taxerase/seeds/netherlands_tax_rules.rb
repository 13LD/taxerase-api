module Taxerase
  module Seeds
    class NetherlandsTaxRules < BaseCountryTaxRules
      tax_rule_data = load_country_tax_data("netherlands")
      LIVE_YEARS = tax_rule_data.fetch("live_years").freeze
      REGIME_KEYS = tax_rule_data.fetch("regime_keys").freeze
      BOX_1_RATES = year_keyed_hash(tax_rule_data.fetch("box_1_rates"), symbolize_values: true).freeze
      GENERAL_TAX_CREDIT_BANDS = year_keyed_hash(tax_rule_data.fetch("general_tax_credit_bands"), symbolize_values: true).freeze
      LABOUR_TAX_CREDIT_BANDS = year_keyed_hash(tax_rule_data.fetch("labour_tax_credit_bands"), symbolize_values: true).freeze
      SELF_EMPLOYED_RULES = year_keyed_hash(tax_rule_data.fetch("self_employed_rules"), symbolize_values: true).freeze
      ADDITIONAL_TAX_CREDIT_RULES = year_keyed_hash(tax_rule_data.fetch("additional_tax_credit_rules"), symbolize_values: true).freeze
      PERSONAL_DEDUCTION_RULES = year_keyed_hash(tax_rule_data.fetch("personal_deduction_rules"), symbolize_values: true).freeze
      ENTREPRENEUR_RELIEF_RULES = year_keyed_hash(tax_rule_data.fetch("entrepreneur_relief_rules"), symbolize_values: true).freeze
      THIRTY_PERCENT_RULING_RULES = year_keyed_hash(tax_rule_data.fetch("thirty_percent_ruling_rules"), symbolize_values: true).freeze
      SOURCE_DEFINITIONS = source_definitions_from(tax_rule_data.fetch("source_definitions")).freeze

      private

      def country_code
        "NL"
      end

      def country_name
        "Netherlands"
      end

      def source_definitions
        SOURCE_DEFINITIONS
      end

      def expected_regime_keys_by_year
        LIVE_YEARS.index_with { REGIME_KEYS }
      end

      def seed_country(country)
        purge_obsolete_regimes!(country)

        LIVE_YEARS.each do |tax_year|
          seed_employee_regime(country, tax_year)
          seed_self_employed_regime(country, tax_year)
        end
      end

      def purge_obsolete_regimes!(country)
        TaxRegime.for_country(country)
          .where(category: %w[employee self_employed])
          .where.not(tax_rule_sets: { tax_year: LIVE_YEARS })
          .find_each(&:destroy!)

        LIVE_YEARS.each do |tax_year|
          TaxRegime
            .for_country_year(country:, tax_year:)
            .where(category: %w[employee self_employed])
            .where.not(key: REGIME_KEYS)
            .find_each(&:destroy!)
        end
      end

      def seed_employee_regime(country, tax_year)
        regime = build_regime(
          country:,
          key: "employee_netherlands",
          name: "Resident employee - Netherlands",
          tax_year:,
          category: "employee",
          region: "Netherlands",
          description: "Resident employee taxed in Dutch Box 1 with nationwide resident rates and heffingskortingen."
        )

        replace_parameters!(regime, {
          "calculation_method" => Taxerase::Netherlands::EmployeeCalculator::CALCULATION_METHOD,
          "thirty_percent_ruling_rate" => THIRTY_PERCENT_RULING_RULES.fetch(tax_year).fetch(:rate),
          "thirty_percent_ruling_standard_threshold" => THIRTY_PERCENT_RULING_RULES.fetch(tax_year).fetch(:standard_threshold),
          "thirty_percent_ruling_under_30_master_threshold" => THIRTY_PERCENT_RULING_RULES.fetch(tax_year).fetch(:under_30_master_threshold),
          "thirty_percent_ruling_salary_cap" => THIRTY_PERCENT_RULING_RULES.fetch(tax_year).fetch(:salary_cap)
        }.merge(year_parameters(ADDITIONAL_TAX_CREDIT_RULES, tax_year))
          .merge(year_parameters(PERSONAL_DEDUCTION_RULES, tax_year)))
        replace_brackets!(regime, "box_1_under_aow", BOX_1_RATES.fetch(tax_year).fetch(:under_aow))
        replace_brackets!(regime, "box_1_aow", BOX_1_RATES.fetch(tax_year).fetch(:aow))
        replace_formula_brackets!(regime, "general_tax_credit_under_aow", GENERAL_TAX_CREDIT_BANDS.fetch(tax_year).fetch(:under_aow))
        replace_formula_brackets!(regime, "general_tax_credit_aow", GENERAL_TAX_CREDIT_BANDS.fetch(tax_year).fetch(:aow))
        replace_formula_brackets!(regime, "labour_tax_credit_under_aow", LABOUR_TAX_CREDIT_BANDS.fetch(tax_year).fetch(:under_aow))
        replace_formula_brackets!(regime, "labour_tax_credit_aow", LABOUR_TAX_CREDIT_BANDS.fetch(tax_year).fetch(:aow))
        replace_source_usages!(regime, employee_source_usages_for(tax_year))
      end

      def seed_self_employed_regime(country, tax_year)
        regime = build_regime(
          country:,
          key: "self_employed_netherlands",
          name: "Resident self-employed - Netherlands",
          tax_year:,
          category: "self_employed",
          region: "Netherlands",
          description: "Resident self-employed person taxed in Dutch Box 1 with ondernemersaftrek, mkb-winstvrijstelling, and Zvw contribution."
        )

        replace_parameters!(
          regime,
          {
            "calculation_method" => Taxerase::Netherlands::SelfEmployedCalculator::CALCULATION_METHOD,
            "self_employed_deduction_under_aow" => SELF_EMPLOYED_RULES.fetch(tax_year).fetch(:self_employed_deduction_under_aow),
            "self_employed_deduction_aow" => SELF_EMPLOYED_RULES.fetch(tax_year).fetch(:self_employed_deduction_aow),
            "sme_profit_exemption_rate" => SELF_EMPLOYED_RULES.fetch(tax_year).fetch(:sme_profit_exemption_rate),
            "zvw_self_assessed_rate" => SELF_EMPLOYED_RULES.fetch(tax_year).fetch(:zvw_self_assessed_rate),
            "zvw_max_contribution_income" => SELF_EMPLOYED_RULES.fetch(tax_year).fetch(:zvw_max_contribution_income)
          }.merge(year_parameters(ADDITIONAL_TAX_CREDIT_RULES, tax_year))
            .merge(year_parameters(PERSONAL_DEDUCTION_RULES, tax_year))
            .merge(year_parameters(ENTREPRENEUR_RELIEF_RULES, tax_year))
        )
        replace_brackets!(regime, "box_1_under_aow", BOX_1_RATES.fetch(tax_year).fetch(:under_aow))
        replace_brackets!(regime, "box_1_aow", BOX_1_RATES.fetch(tax_year).fetch(:aow))
        replace_formula_brackets!(regime, "general_tax_credit_under_aow", GENERAL_TAX_CREDIT_BANDS.fetch(tax_year).fetch(:under_aow))
        replace_formula_brackets!(regime, "general_tax_credit_aow", GENERAL_TAX_CREDIT_BANDS.fetch(tax_year).fetch(:aow))
        replace_formula_brackets!(regime, "labour_tax_credit_under_aow", LABOUR_TAX_CREDIT_BANDS.fetch(tax_year).fetch(:under_aow))
        replace_formula_brackets!(regime, "labour_tax_credit_aow", LABOUR_TAX_CREDIT_BANDS.fetch(tax_year).fetch(:aow))
        replace_source_usages!(regime, self_employed_source_usages_for(tax_year))
      end

      def employee_source_usages_for(tax_year)
        case tax_year
        when 2024
          [
            { source_key: "nl_2024_box_1_rates", usage_type: "box_1_rates", label: "Belastingdienst: Box 1 rates 2024" },
            { source_key: "nl_2024_general_tax_credit", usage_type: "general_tax_credit", label: "Belastingdienst: general tax credit 2024" },
            { source_key: "nl_2024_labour_tax_credit", usage_type: "labour_tax_credit", label: "Belastingdienst: labour tax credit 2024" },
            { source_key: "nl_2024_expat_scheme_conditions", usage_type: "thirty_percent_ruling_conditions", label: "Belastingdienst: 30% ruling thresholds 2024" },
            { source_key: "nl_2024_expat_scheme_cap", usage_type: "thirty_percent_ruling_cap", label: "Belastingdienst: 30% ruling salary cap 2024" },
            { source_key: "nl_2024_zvw_rates", usage_type: "zvw", label: "Belastingdienst: Zvw contribution table 2024" }
          ]
        when 2025
          [
            { source_key: "nl_2025_box_1_rates", usage_type: "box_1_rates", label: "Belastingdienst: Box 1 rates 2025" },
            { source_key: "nl_2025_general_tax_credit", usage_type: "general_tax_credit", label: "Belastingdienst: general tax credit 2025" },
            { source_key: "nl_2025_labour_tax_credit", usage_type: "labour_tax_credit", label: "Belastingdienst: labour tax credit 2025" },
            { source_key: "nl_2025_expat_scheme_conditions", usage_type: "thirty_percent_ruling_conditions", label: "Belastingdienst: 30% ruling thresholds 2025" },
            { source_key: "nl_2025_expat_scheme_cap", usage_type: "thirty_percent_ruling_cap", label: "Belastingdienst: 30% ruling salary cap 2025" },
            { source_key: "nl_2025_zvw_rates", usage_type: "zvw", label: "Belastingdienst: Zvw contribution table 2025" }
          ]
        else
          raise ArgumentError, "Unsupported Netherlands employee source year #{tax_year}"
        end
      end

      def self_employed_source_usages_for(tax_year)
        case tax_year
        when 2024
          [
            { source_key: "nl_2024_box_1_rates", usage_type: "box_1_rates", label: "Belastingdienst: Box 1 rates 2024" },
            { source_key: "nl_2024_general_tax_credit", usage_type: "general_tax_credit", label: "Belastingdienst: general tax credit 2024" },
            { source_key: "nl_2024_labour_tax_credit", usage_type: "labour_tax_credit", label: "Belastingdienst: labour tax credit 2024" },
            { source_key: "nl_2024_entrepreneur_reliefs", usage_type: "entrepreneur_reliefs", label: "Belastingdienst: ondernemersaftrek 2024" },
            { source_key: "nl_2024_mkb_profit_exemption", usage_type: "mkb_profit_exemption", label: "Belastingdienst: SME profit exemption" },
            { source_key: "nl_2024_zvw_rates", usage_type: "zvw", label: "Belastingdienst: Zvw contribution table 2024" }
          ]
        when 2025
          [
            { source_key: "nl_2025_box_1_rates", usage_type: "box_1_rates", label: "Belastingdienst: Box 1 rates 2025" },
            { source_key: "nl_2025_general_tax_credit", usage_type: "general_tax_credit", label: "Belastingdienst: general tax credit 2025" },
            { source_key: "nl_2025_labour_tax_credit", usage_type: "labour_tax_credit", label: "Belastingdienst: labour tax credit 2025" },
            { source_key: "nl_2025_self_employed_deduction", usage_type: "self_employed_deduction", label: "Belastingdienst: self-employed deduction 2025" },
            { source_key: "nl_2025_mkb_profit_exemption", usage_type: "mkb_profit_exemption", label: "Belastingdienst: SME profit exemption 2025" },
            { source_key: "nl_2025_zvw_rates", usage_type: "zvw", label: "Belastingdienst: Zvw contribution table 2025" }
          ]
        else
          raise ArgumentError, "Unsupported Netherlands self-employed source year #{tax_year}"
        end
      end

      def year_parameters(rule_set, tax_year)
        rule_set.fetch(tax_year, {}).transform_keys(&:to_s)
      end
    end
  end
end
