module Taxerase
  module Seeds
    class PortugalTaxRules < BaseCountryTaxRules
      tax_rule_data = load_country_tax_data("portugal")
      LIVE_YEARS = tax_rule_data.fetch("live_years").freeze
      REGIME_KEYS = tax_rule_data.fetch("regime_keys").freeze
      INCOME_TAX_BRACKETS = year_keyed_hash(tax_rule_data.fetch("income_tax_brackets")).freeze
      YEAR_PARAMETERS = year_keyed_hash(tax_rule_data.fetch("year_parameters")).freeze
      SOURCE_DEFINITIONS = source_definitions_from(tax_rule_data.fetch("source_definitions")).freeze

      def country_code
        "PT"
      end

      def country_name
        "Portugal"
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

      def shared_deduction_parameters(tax_year)
        YEAR_PARAMETERS.fetch(tax_year).merge(
          "dependent_deduction" => 600,
          "dependent_under_three_bonus" => 126,
          "ascendant_deduction" => 525,
          "single_ascendant_bonus" => 110,
          "general_family_deduction_rate" => 0.35,
          "general_family_deduction_cap" => 250,
          "health_expenses_deduction_rate" => 0.15,
          "health_expenses_deduction_cap" => 1000,
          "education_expenses_deduction_rate" => 0.30,
          "education_expenses_deduction_cap" => 800,
          "housing_rent_deduction_rate" => 0.15,
          "housing_rent_deduction_cap" => 800,
          "alimony_deduction_rate" => 0.20,
          "care_home_deduction_rate" => 0.25,
          "care_home_deduction_cap" => 403.75,
          "domestic_work_deduction_rate" => 0.05,
          "domestic_work_deduction_cap" => 200
        )
      end

      def summary_year?(tax_year)
        tax_year == 2024
      end

      def rates_source_key(tax_year)
        summary_year?(tax_year) ? "pt_2024_irs_summary" : "pt_#{tax_year}_irs_rates"
      end

      def rates_source_label(tax_year)
        summary_year?(tax_year) ? "AT: IRS 2024 rates and deduction summary" : "AT: CIRS article 68 general IRS rates"
      end

      def employee_deduction_source_key(tax_year)
        summary_year?(tax_year) ? "pt_2024_irs_summary" : "pt_#{tax_year}_employee_deductions"
      end

      def employee_deduction_source_label(tax_year)
        summary_year?(tax_year) ? "AT: IRS 2024 work-income deductions" : "AT: CIRS article 25 work-income deductions"
      end

      def family_deduction_source_key(tax_year)
        summary_year?(tax_year) ? "pt_2024_irs_summary" : "pt_#{tax_year}_family_deductions"
      end

      def family_deduction_source_label(tax_year)
        summary_year?(tax_year) ? "AT: IRS 2024 family deductions" : "AT: CIRS article 78-A dependent and ascendant deductions"
      end

      def expense_deduction_source_key(tax_year)
        summary_year?(tax_year) ? "pt_2024_irs_summary" : "pt_#{tax_year}_expense_deductions"
      end

      def expense_deduction_source_label(tax_year)
        summary_year?(tax_year) ? "AT: IRS 2024 household deductions" : "AT: household tax deductions"
      end

      def seed_employee_regime(country, tax_year)
        regime = build_regime(
          country:,
          key: "employee_portugal",
          name: "Resident employee - Portugal",
          tax_year:,
          category: "employee",
          region: "Portugal",
          description: "Resident employee in mainland Portugal with employee social security, category A specific deductions, and selected household tax deductions."
        )

        replace_parameters!(regime, shared_deduction_parameters(tax_year).merge(
          "calculation_method" => Taxerase::Portugal::EmployeeCalculator::CALCULATION_METHOD,
          "employee_social_security_rate" => 0.11
        ))
        replace_brackets!(regime, "income_tax", INCOME_TAX_BRACKETS.fetch(tax_year))
        replace_source_usages!(regime, [
          {
            source_key: rates_source_key(tax_year),
            usage_type: "income_tax",
            label: rates_source_label(tax_year)
          },
          {
            source_key: employee_deduction_source_key(tax_year),
            usage_type: "specific_deduction",
            label: employee_deduction_source_label(tax_year)
          },
          {
            source_key: family_deduction_source_key(tax_year),
            usage_type: "family_deductions",
            label: family_deduction_source_label(tax_year)
          },
          {
            source_key: expense_deduction_source_key(tax_year),
            usage_type: "expense_deductions",
            label: expense_deduction_source_label(tax_year)
          },
          {
            source_key: "pt_#{tax_year}_employee_social_security",
            usage_type: "social_security",
            label: "Segurança Social: employee contributions"
          }
        ])
      end

      def seed_self_employed_regime(country, tax_year)
        regime = build_regime(
          country:,
          key: "self_employed_portugal",
          name: "Simplified self-employed - Portugal",
          tax_year:,
          category: "self_employed",
          region: "Portugal",
          description: "Resident self-employed person in mainland Portugal using the simplified category B regime with estimated social security and selected household tax deductions."
        )

        replace_parameters!(regime, shared_deduction_parameters(tax_year).merge(
          "calculation_method" => Taxerase::Portugal::SelfEmployedCalculator::CALCULATION_METHOD,
          "self_employed_social_security_rate" => 0.214
        ))
        replace_brackets!(regime, "income_tax", INCOME_TAX_BRACKETS.fetch(tax_year))
        replace_source_usages!(regime, [
          {
            source_key: rates_source_key(tax_year),
            usage_type: "income_tax",
            label: rates_source_label(tax_year)
          },
          {
            source_key: "pt_#{tax_year}_self_employed_regime",
            usage_type: "simplified_regime",
            label: "AT: CIRS article 31 simplified regime"
          },
          {
            source_key: family_deduction_source_key(tax_year),
            usage_type: "family_deductions",
            label: family_deduction_source_label(tax_year)
          },
          {
            source_key: expense_deduction_source_key(tax_year),
            usage_type: "expense_deductions",
            label: expense_deduction_source_label(tax_year)
          },
          {
            source_key: "pt_#{tax_year}_self_employed_social_security",
            usage_type: "social_security",
            label: "Segurança Social: self-employed workers"
          }
        ])
      end
    end
  end
end
