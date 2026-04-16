module Taxerase
  module Seeds
    class PolandTaxRules < BaseCountryTaxRules
      LIVE_YEARS = [ 2025, 2026 ].freeze
      REGIME_KEYS = %w[employee_poland self_employed_poland].freeze
      PIT_SCALE_BRACKETS = [
        [ 120_000, 0.12 ],
        [ nil, 0.32 ]
      ].freeze
      YEAR_RULES = {
        2025 => {
          monthly_minimum_wage: 4666,
          monthly_standard_social_base: 5203.80,
          monthly_preferential_social_base: 1399.80,
          monthly_small_zus_plus_min_base: 1399.80,
          monthly_small_zus_plus_max_base: 5203.80,
          monthly_general_health_minimum: 314.96,
          monthly_lump_sum_health_base_low: 5129.51,
          monthly_lump_sum_health_base_mid: 8549.18,
          monthly_lump_sum_health_base_high: 15388.53
        },
        2026 => {
          monthly_minimum_wage: 4806,
          monthly_standard_social_base: 5652,
          monthly_preferential_social_base: 1441.80,
          monthly_small_zus_plus_min_base: 1441.80,
          monthly_small_zus_plus_max_base: 5652,
          monthly_general_health_minimum: 432.54,
          monthly_lump_sum_health_base_low: 5537.18,
          monthly_lump_sum_health_base_mid: 9228.64,
          monthly_lump_sum_health_base_high: 16611.55
        }
      }.freeze
      SOURCE_DEFINITIONS = {
        "pl_2025_pit_scale" => {
          title: "Podatki.gov.pl: general tax scale settlement",
          authority_name: "Podatki.gov.pl",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.podatki.gov.pl/podatki-firmowe/pit/informacje-podstawowe/co-jest-opodatkowane/rozliczenie-dochodow-opodatkowanych-skala-podatkowa/"
        },
        "pl_2025_pit_rates" => {
          title: "Podatki.gov.pl: general tax scale settlement",
          authority_name: "Podatki.gov.pl",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.podatki.gov.pl/podatki-firmowe/pit/informacje-podstawowe/co-jest-opodatkowane/rozliczenie-dochodow-opodatkowanych-skala-podatkowa/"
        },
        "pl_2025_flat_tax" => {
          title: "Podatki.gov.pl: personal income tax rates",
          authority_name: "Podatki.gov.pl",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.podatki.gov.pl/en/residents/personal-income-tax-rates/"
        },
        "pl_2025_lump_sum" => {
          title: "Podatki.gov.pl: lump-sum taxation of recorded revenue",
          authority_name: "Podatki.gov.pl",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.podatki.gov.pl/pit/abc-pit/ryczalt-od-przychodow-ewidencjonowanych/?altTemplate=ArticlePdf&download=True"
        },
        "pl_2025_employee_costs" => {
          title: "Podatki.gov.pl: employee deductible costs",
          authority_name: "Podatki.gov.pl",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.podatki.gov.pl/pit/koszty-uzyskania-przychodow/"
        },
        "pl_2025_child_relief" => {
          title: "Podatki.gov.pl: child relief",
          authority_name: "Podatki.gov.pl",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.podatki.gov.pl/ulgi-i-odliczenia/ulga-na-dziecko-pit/"
        },
        "pl_2025_relief_for_young" => {
          title: "Podatki.gov.pl: relief for young people",
          authority_name: "Podatki.gov.pl",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.podatki.gov.pl/ulgi/ulga-dla-mlodych-pit/"
        },
        "pl_2025_return_relief" => {
          title: "Podatki.gov.pl: return relief",
          authority_name: "Podatki.gov.pl",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.podatki.gov.pl/ulgi/ulga-na-powrot-pit/"
        },
        "pl_2025_family_4plus_relief" => {
          title: "Podatki.gov.pl: family 4+ relief",
          authority_name: "Podatki.gov.pl",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.podatki.gov.pl/ulgi/ulga-dla-rodzin-4plus-pit/"
        },
        "pl_2025_working_senior_relief" => {
          title: "Podatki.gov.pl: working senior relief",
          authority_name: "Podatki.gov.pl",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.podatki.gov.pl/ulgi/ulga-dla-pracujacych-seniorow-pit/"
        },
        "pl_2025_ppk" => {
          title: "MojePPK.pl: basic employee and employer PPK contribution rates",
          authority_name: "MojePPK.pl",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.mojeppk.pl/faq.html"
        },
        "pl_2025_zus_social" => {
          title: "ZUS: social contribution amounts for entrepreneurs in 2025",
          authority_name: "ZUS",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.zus.pl/en/-/nowe-wysoko%C5%9Bci-sk%C5%82adek-na-ubezpieczenia-spo%C5%82eczne-w-2025-r."
        },
        "pl_2025_zus_health_general" => {
          title: "ZUS: changes in entrepreneur health contributions from 1 January 2025",
          authority_name: "ZUS",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.zus.pl/-/zmiany-w-sk%C5%82adce-zdrowotnej-op%C5%82acanej-przez-przedsi%C4%99biorc%C3%B3w-od-1-stycznia-2025-r."
        },
        "pl_2025_zus_health_lump_sum" => {
          title: "ZUS: health contribution thresholds for lump-sum entrepreneurs in 2025",
          authority_name: "ZUS",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.zus.pl/en/-/informacja-w-sprawie-podstawy-wymiaru-sk%C5%82adki-oraz-kwoty-sk%C5%82adki-na-ubezpieczenie-zdrowotne-w-2025-r.-dla-niekt%C3%B3rych-grup-ubezpieczonych"
        },
        "pl_2026_pit_rates" => {
          title: "Podatki.gov.pl: how to calculate PIT",
          authority_name: "Podatki.gov.pl",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2026,
          url: "https://www.podatki.gov.pl/pit/abc-pit/jak-obliczyc-podatek/"
        },
        "pl_2026_employee_costs" => {
          title: "Podatki.gov.pl: employee deductible-cost amounts",
          authority_name: "Podatki.gov.pl",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2026,
          url: "https://www.podatki.gov.pl/twoj-e-pit/pytania-i-odpowiedzi/koszty-uzyskania-przychodow/71-ile-wynosza-koszty-uzyskania-przychodow-w-rozliczeniu-pit-za-2025-rok/"
        },
        "pl_2026_child_relief" => {
          title: "Podatki.gov.pl: child relief",
          authority_name: "Podatki.gov.pl",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2026,
          url: "https://www.podatki.gov.pl/ulgi-i-odliczenia/ulga-na-dziecko-pit/"
        },
        "pl_2026_relief_for_young" => {
          title: "Podatki.gov.pl: relief for young people",
          authority_name: "Podatki.gov.pl",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2026,
          url: "https://www.podatki.gov.pl/pit/osoba-nieprowadzaca-dzialalnosci-gospodarczej/mam-mniej-niz-26-lat/"
        },
        "pl_2026_return_relief" => {
          title: "Podatki.gov.pl: return relief",
          authority_name: "Podatki.gov.pl",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2026,
          url: "https://www.podatki.gov.pl/ulgi/ulga-na-powrot-pit/"
        },
        "pl_2026_family_4plus_relief" => {
          title: "Podatki.gov.pl: family 4+ relief declaration",
          authority_name: "Podatki.gov.pl",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2026,
          url: "https://www.podatki.gov.pl/podatki-osobiste/pit/wzor-oswiadczenia-ulga-dla-rodzin-4plus/"
        },
        "pl_2026_working_senior_relief" => {
          title: "Podatki.gov.pl: working senior relief",
          authority_name: "Podatki.gov.pl",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2026,
          url: "https://www.podatki.gov.pl/ulgi/ulga-dla-pracujacych-seniorow-pit/"
        },
        "pl_2026_ppk" => {
          title: "MojePPK.pl: basic employee and employer PPK contribution rates",
          authority_name: "MojePPK.pl",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2026,
          url: "https://www.mojeppk.pl/faq.html"
        },
        "pl_2026_zus_social_rates" => {
          title: "ZUS: social-security contribution rates in Poland",
          authority_name: "ZUS",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2026,
          url: "https://www.zus.pl/documents/10182/167567/Zabezpieczenie%2Bspo%C5%82eczne%2Bw%2BPolsce.pdf/387eb8f7-0522-4f74-ace3-907cd6b1e80f?t=1706611640758"
        },
        "pl_2026_zus_health_general" => {
          title: "ZUS: minimum entrepreneur health contribution in 2026",
          authority_name: "ZUS",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2026,
          url: "https://www.zus.pl/-/przedsi%C4%99biorcy-opodatkowani-na-zasadach-og%C3%B3lnych-lub-w-formie-karty-podatkowej.-minimalna-sk%C5%82adka-na-ubezpieczenie-zdrowotne-w-2026-r.?redirect=%2F"
        },
        "pl_2026_zus_health_lump_sum" => {
          title: "ZUS: health contribution calculator for entrepreneurs",
          authority_name: "ZUS",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2026,
          url: "https://www.zus.pl/firmy/przedsiebiorco-przeczytaj-wazne/kalkulator-skladki-zdrowotnej"
        },
        "pl_2026_flat_tax" => {
          title: "Podatki.gov.pl: personal income tax rates",
          authority_name: "Podatki.gov.pl",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2026,
          url: "https://www.podatki.gov.pl/en/residents/personal-income-tax-rates/"
        },
        "pl_2026_lump_sum" => {
          title: "Podatki.gov.pl: lump-sum taxation of recorded revenue",
          authority_name: "Podatki.gov.pl",
          country_code: "PL",
          jurisdiction: "Poland",
          source_type: "guidance",
          tax_year: 2026,
          url: "https://www.podatki.gov.pl/pit/abc-pit/ryczalt-od-przychodow-ewidencjonowanych/?altTemplate=ArticlePdf&download=True"
        }
      }.freeze

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
