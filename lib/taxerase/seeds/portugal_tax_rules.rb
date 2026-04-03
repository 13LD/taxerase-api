module Taxerase
  module Seeds
    class PortugalTaxRules < BaseCountryTaxRules
      LIVE_YEARS = [ 2024, 2025, 2026 ].freeze
      REGIME_KEYS = %w[employee_portugal self_employed_portugal].freeze
      INCOME_TAX_BRACKETS = {
        2024 => [
          [ 7_703, 0.13 ],
          [ 11_623, 0.165 ],
          [ 16_472, 0.22 ],
          [ 21_321, 0.25 ],
          [ 27_146, 0.32 ],
          [ 39_791, 0.355 ],
          [ 43_000, 0.435 ],
          [ 80_000, 0.45 ],
          [ nil, 0.48 ]
        ],
        2025 => [
          [ 8_059, 0.13 ],
          [ 12_160, 0.165 ],
          [ 17_233, 0.22 ],
          [ 22_306, 0.25 ],
          [ 28_400, 0.32 ],
          [ 41_629, 0.355 ],
          [ 44_987, 0.435 ],
          [ 83_696, 0.45 ],
          [ nil, 0.48 ]
        ],
        2026 => [
          [ 8_342, 0.125 ],
          [ 12_587, 0.157 ],
          [ 17_838, 0.212 ],
          [ 23_089, 0.241 ],
          [ 29_397, 0.311 ],
          [ 43_090, 0.349 ],
          [ 46_566, 0.431 ],
          [ 86_634, 0.446 ],
          [ nil, 0.48 ]
        ]
      }.freeze
      YEAR_PARAMETERS = {
        2024 => {
          "specific_deduction_floor" => 4_350.24,
          "taxpayer_disability_deduction" => 2_037.04
        },
        2025 => {
          "specific_deduction_floor" => 4_462.15,
          "taxpayer_disability_deduction" => 2_090.0
        },
        2026 => {
          "specific_deduction_floor" => 4_587.09,
          "taxpayer_disability_deduction" => 2_148.52
        }
      }.freeze
      SOURCE_DEFINITIONS = {
        "pt_2024_irs_summary" => {
          title: "Autoridade Tributária: IRS 2024 deductions, benefits, and rates",
          authority_name: "Autoridade Tributária e Aduaneira",
          country_code: "PT",
          jurisdiction: "Portugal",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://info.portaldasfinancas.gov.pt/pt/apoio_contribuinte/IRS/IRS_2024/Paginas/5_Deducoes_beneficios_taxas.aspx"
        },
        "pt_2025_irs_rates" => {
          title: "Autoridade Tributária: CIRS article 68 general rates (2025 version)",
          authority_name: "Autoridade Tributária e Aduaneira",
          country_code: "PT",
          jurisdiction: "Portugal",
          source_type: "tax_code",
          tax_year: 2025,
          url: "https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/ra/Pages/irs68_ra202507.aspx"
        },
        "pt_2026_irs_rates" => {
          title: "Autoridade Tributária: CIRS article 68 general rates",
          authority_name: "Autoridade Tributária e Aduaneira",
          country_code: "PT",
          jurisdiction: "Portugal",
          source_type: "tax_code",
          tax_year: 2026,
          url: "https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs68.aspx"
        },
        "pt_2025_employee_deductions" => {
          title: "Autoridade Tributária: CIRS article 25 work-income deductions",
          authority_name: "Autoridade Tributária e Aduaneira",
          country_code: "PT",
          jurisdiction: "Portugal",
          source_type: "tax_code",
          tax_year: 2025,
          url: "https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs25.aspx"
        },
        "pt_2026_employee_deductions" => {
          title: "Autoridade Tributária: CIRS article 25 work-income deductions",
          authority_name: "Autoridade Tributária e Aduaneira",
          country_code: "PT",
          jurisdiction: "Portugal",
          source_type: "tax_code",
          tax_year: 2026,
          url: "https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs25.aspx"
        },
        "pt_2024_self_employed_regime" => {
          title: "Autoridade Tributária: CIRS article 31 simplified regime",
          authority_name: "Autoridade Tributária e Aduaneira",
          country_code: "PT",
          jurisdiction: "Portugal",
          source_type: "tax_code",
          tax_year: 2024,
          url: "https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs31.aspx"
        },
        "pt_2025_self_employed_regime" => {
          title: "Autoridade Tributária: CIRS article 31 simplified regime",
          authority_name: "Autoridade Tributária e Aduaneira",
          country_code: "PT",
          jurisdiction: "Portugal",
          source_type: "tax_code",
          tax_year: 2025,
          url: "https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs31.aspx"
        },
        "pt_2026_self_employed_regime" => {
          title: "Autoridade Tributária: CIRS article 31 simplified regime",
          authority_name: "Autoridade Tributária e Aduaneira",
          country_code: "PT",
          jurisdiction: "Portugal",
          source_type: "tax_code",
          tax_year: 2026,
          url: "https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs31.aspx"
        },
        "pt_2025_family_deductions" => {
          title: "Autoridade Tributária: CIRS article 78-A dependent and ascendant deductions",
          authority_name: "Autoridade Tributária e Aduaneira",
          country_code: "PT",
          jurisdiction: "Portugal",
          source_type: "tax_code",
          tax_year: 2025,
          url: "https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs78a.aspx"
        },
        "pt_2026_family_deductions" => {
          title: "Autoridade Tributária: CIRS article 78-A dependent and ascendant deductions",
          authority_name: "Autoridade Tributária e Aduaneira",
          country_code: "PT",
          jurisdiction: "Portugal",
          source_type: "tax_code",
          tax_year: 2026,
          url: "https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs78a.aspx"
        },
        "pt_2025_expense_deductions" => {
          title: "Autoridade Tributária: CIRS deduction articles 78-B, 78-E, 83-A, 84, 87, and 78-H",
          authority_name: "Autoridade Tributária e Aduaneira",
          country_code: "PT",
          jurisdiction: "Portugal",
          source_type: "tax_code",
          tax_year: 2025,
          url: "https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs78b.aspx"
        },
        "pt_2026_expense_deductions" => {
          title: "Autoridade Tributária: CIRS deduction articles 78-B, 78-E, 83-A, 84, 87, and 78-H",
          authority_name: "Autoridade Tributária e Aduaneira",
          country_code: "PT",
          jurisdiction: "Portugal",
          source_type: "tax_code",
          tax_year: 2026,
          url: "https://info.portaldasfinancas.gov.pt/pt/informacao_fiscal/codigos_tributarios/cirs_rep/Pages/irs78b.aspx"
        },
        "pt_2024_employee_social_security" => {
          title: "Segurança Social: employee contributions",
          authority_name: "Segurança Social",
          country_code: "PT",
          jurisdiction: "Portugal",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://en.seg-social.pt/pt/employd-persons"
        },
        "pt_2025_employee_social_security" => {
          title: "Segurança Social: employee contributions",
          authority_name: "Segurança Social",
          country_code: "PT",
          jurisdiction: "Portugal",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://en.seg-social.pt/pt/employd-persons"
        },
        "pt_2026_employee_social_security" => {
          title: "Segurança Social: employee contributions",
          authority_name: "Segurança Social",
          country_code: "PT",
          jurisdiction: "Portugal",
          source_type: "guidance",
          tax_year: 2026,
          url: "https://en.seg-social.pt/pt/employd-persons"
        },
        "pt_2024_self_employed_social_security" => {
          title: "Segurança Social: self-employed workers",
          authority_name: "Segurança Social",
          country_code: "PT",
          jurisdiction: "Portugal",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://en.seg-social.pt/self-employd-workers"
        },
        "pt_2025_self_employed_social_security" => {
          title: "Segurança Social: self-employed workers",
          authority_name: "Segurança Social",
          country_code: "PT",
          jurisdiction: "Portugal",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://en.seg-social.pt/self-employd-workers"
        },
        "pt_2026_self_employed_social_security" => {
          title: "Segurança Social: self-employed workers",
          authority_name: "Segurança Social",
          country_code: "PT",
          jurisdiction: "Portugal",
          source_type: "guidance",
          tax_year: 2026,
          url: "https://en.seg-social.pt/self-employd-workers"
        }
      }.freeze

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
        country.tax_regimes.where(category: %w[employee self_employed]).where.not(tax_year: LIVE_YEARS).find_each(&:destroy!)

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
