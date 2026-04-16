module Taxerase
  module Seeds
    class NetherlandsTaxRules < BaseCountryTaxRules
      LIVE_YEARS = [ 2024, 2025 ].freeze
      REGIME_KEYS = %w[employee_netherlands self_employed_netherlands].freeze
      BOX_1_RATES = {
        2024 => {
          under_aow: [
            [ 75_518, 0.3697 ],
            [ nil, 0.495 ]
          ],
          aow: [
            [ 38_098, 0.1907 ],
            [ 75_518, 0.3697 ],
            [ nil, 0.495 ]
          ]
        },
        2025 => {
          under_aow: [
            [ 38_441, 0.3582 ],
            [ 76_817, 0.3748 ],
            [ nil, 0.495 ]
          ],
          aow: [
            [ 38_441, 0.1792 ],
            [ 76_817, 0.3748 ],
            [ nil, 0.495 ]
          ]
        }
      }.freeze
      GENERAL_TAX_CREDIT_BANDS = {
        2024 => {
          under_aow: [
            { lower_bound: nil, upper_bound: 24_812, base_min: 3362, rate: 0, label: "max_credit" },
            { lower_bound: 24_812, upper_bound: 75_518, base_min: 3362, rate: -0.06630, label: "phase_out" },
            { lower_bound: 75_518, upper_bound: nil, base_min: 0, rate: 0, label: "no_credit" }
          ],
          aow: [
            { lower_bound: nil, upper_bound: 24_812, base_min: 1735, rate: 0, label: "max_credit" },
            { lower_bound: 24_812, upper_bound: 75_518, base_min: 1735, rate: -0.03421, label: "phase_out" },
            { lower_bound: 75_518, upper_bound: nil, base_min: 0, rate: 0, label: "no_credit" }
          ]
        },
        2025 => {
          under_aow: [
            { lower_bound: nil, upper_bound: 28_406, base_min: 3068, rate: 0, label: "max_credit" },
            { lower_bound: 28_406, upper_bound: 76_817, base_min: 3068, rate: -0.06337, label: "phase_out" },
            { lower_bound: 76_817, upper_bound: nil, base_min: 0, rate: 0, label: "no_credit" }
          ],
          aow: [
            { lower_bound: nil, upper_bound: 28_406, base_min: 1536, rate: 0, label: "max_credit" },
            { lower_bound: 28_406, upper_bound: 76_817, base_min: 1536, rate: -0.03170, label: "phase_out" },
            { lower_bound: 76_817, upper_bound: nil, base_min: 0, rate: 0, label: "no_credit" }
          ]
        }
      }.freeze
      LABOUR_TAX_CREDIT_BANDS = {
        2024 => {
          under_aow: [
            { lower_bound: nil, upper_bound: 11_490, base_min: 0, rate: 0.08425, label: "phase_1" },
            { lower_bound: 11_490, upper_bound: 24_820, base_min: 968, rate: 0.31433, label: "phase_2" },
            { lower_bound: 24_820, upper_bound: 39_957, base_min: 5158, rate: 0.02471, label: "phase_3" },
            { lower_bound: 39_957, upper_bound: 124_934, base_min: 5532, rate: -0.06510, label: "phase_4" },
            { lower_bound: 124_934, upper_bound: nil, base_min: 0, rate: 0, label: "no_credit" }
          ],
          aow: [
            { lower_bound: nil, upper_bound: 11_490, base_min: 0, rate: 0.04346, label: "phase_1" },
            { lower_bound: 11_490, upper_bound: 24_820, base_min: 501, rate: 0.16214, label: "phase_2" },
            { lower_bound: 24_820, upper_bound: 39_957, base_min: 2662, rate: 0.01275, label: "phase_3" },
            { lower_bound: 39_957, upper_bound: 124_934, base_min: 2854, rate: -0.03358, label: "phase_4" },
            { lower_bound: 124_934, upper_bound: nil, base_min: 0, rate: 0, label: "no_credit" }
          ]
        },
        2025 => {
          under_aow: [
            { lower_bound: nil, upper_bound: 12_169, base_min: 0, rate: 0.08053, label: "phase_1" },
            { lower_bound: 12_169, upper_bound: 26_288, base_min: 980, rate: 0.30030, label: "phase_2" },
            { lower_bound: 26_288, upper_bound: 43_071, base_min: 5220, rate: 0.02258, label: "phase_3" },
            { lower_bound: 43_071, upper_bound: 129_078, base_min: 5599, rate: -0.06510, label: "phase_4" },
            { lower_bound: 129_078, upper_bound: nil, base_min: 0, rate: 0, label: "no_credit" }
          ],
          aow: [
            { lower_bound: nil, upper_bound: 12_169, base_min: 0, rate: 0.04029, label: "phase_1" },
            { lower_bound: 12_169, upper_bound: 26_288, base_min: 491, rate: 0.15023, label: "phase_2" },
            { lower_bound: 26_288, upper_bound: 43_071, base_min: 2612, rate: 0.01130, label: "phase_3" },
            { lower_bound: 43_071, upper_bound: 129_078, base_min: 2802, rate: -0.03257, label: "phase_4" },
            { lower_bound: 129_078, upper_bound: nil, base_min: 0, rate: 0, label: "no_credit" }
          ]
        }
      }.freeze
      SELF_EMPLOYED_RULES = {
        2024 => {
          self_employed_deduction_under_aow: 3750,
          self_employed_deduction_aow: 1875,
          sme_profit_exemption_rate: 0.1331,
          zvw_self_assessed_rate: 0.0532,
          zvw_max_contribution_income: 71_628
        },
        2025 => {
          self_employed_deduction_under_aow: 2470,
          self_employed_deduction_aow: 1235,
          sme_profit_exemption_rate: 0.127,
          zvw_self_assessed_rate: 0.0526,
          zvw_max_contribution_income: 75_864
        }
      }.freeze
      THIRTY_PERCENT_RULING_RULES = {
        2024 => {
          rate: 0.30,
          standard_threshold: 46_107,
          under_30_master_threshold: 35_048,
          salary_cap: 233_000
        },
        2025 => {
          rate: 0.30,
          standard_threshold: 46_660,
          under_30_master_threshold: 35_468,
          salary_cap: 246_000
        }
      }.freeze
      SOURCE_DEFINITIONS = {
        "nl_2024_box_1_rates" => {
          title: "Belastingdienst: Box 1 income tax rates 2024",
          authority_name: "Belastingdienst",
          country_code: "NL",
          jurisdiction: "Netherlands",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://www.belastingdienst.nl/wps/wcm/connect/bldcontentnl/belastingdienst/prive/inkomstenbelasting/heffingskortingen_boxen_tarieven/boxen_en_tarieven/box_1/box_1"
        },
        "nl_2024_general_tax_credit" => {
          title: "Belastingdienst: general tax credit table 2024",
          authority_name: "Belastingdienst",
          country_code: "NL",
          jurisdiction: "Netherlands",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://www.belastingdienst.nl/wps/wcm/connect/bldcontentnl/belastingdienst/prive/inkomstenbelasting/heffingskortingen_boxen_tarieven/heffingskortingen/algemene_heffingskorting/tabel-algemene-heffingskorting-2024"
        },
        "nl_2024_labour_tax_credit" => {
          title: "Belastingdienst: labour tax credit table 2024",
          authority_name: "Belastingdienst",
          country_code: "NL",
          jurisdiction: "Netherlands",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://www.belastingdienst.nl/wps/wcm/connect/bldcontentnl/belastingdienst/prive/inkomstenbelasting/heffingskortingen_boxen_tarieven/heffingskortingen/arbeidskorting/tabel-arbeidskorting-2024"
        },
        "nl_2024_entrepreneur_reliefs" => {
          title: "Belastingdienst: entrepreneurs deductions and SME profit exemption 2024",
          authority_name: "Belastingdienst",
          country_code: "NL",
          jurisdiction: "Netherlands",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://www.belastingdienst.nl/wps/wcm/connect/fisin/fisin2024/ondernemersaftrek_en_investeringsaftrek"
        },
        "nl_2024_mkb_profit_exemption" => {
          title: "Belastingdienst: SME profit exemption",
          authority_name: "Belastingdienst",
          country_code: "NL",
          jurisdiction: "Netherlands",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://www.belastingdienst.nl/wps/wcm/connect/bldcontentnl/belastingdienst/zakelijk/winst/inkomstenbelasting/inkomstenbelasting_voor_ondernemers/mkb_winstvrijstelling"
        },
        "nl_2024_zvw_rates" => {
          title: "Belastingdienst: werkgeversheffing Zvw or own Zvw contribution",
          authority_name: "Belastingdienst",
          country_code: "NL",
          jurisdiction: "Netherlands",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://www.belastingdienst.nl/wps/wcm/connect/bldcontentnl/belastingdienst/prive/werk_en_inkomen/zorgverzekeringswet/bijdrage_zorgverzekeringswet/tabel_werkgeversheffing_zvw_of_bijdrage_zvw/"
        },
        "nl_2024_expat_scheme_conditions" => {
          title: "Belastingdienst: Expat Scheme conditions and salary thresholds",
          authority_name: "Belastingdienst",
          country_code: "NL",
          jurisdiction: "Netherlands",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://www.belastingdienst.nl/wps/wcm/connect/nl/buitenland/content/ik-kom-in-nederland-werken-30-procent-regeling-aanvragen"
        },
        "nl_2024_expat_scheme_cap" => {
          title: "Belastingdienst: 30% ruling salary cap via 2024 WNT norm",
          authority_name: "Belastingdienst",
          country_code: "NL",
          jurisdiction: "Netherlands",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://www.belastingdienst.nl/wps/wcm/connect/bldcontentnl/belastingdienst/zakelijk/internationaal/personeel/u_bent_niet_in_nederland_gevestigd_loonheffingen_inhouden/als_u_loonheffingen_gaat_inhouden/extraterritoriale_kosten_en_de_30procentregeling/voorwaarden_voor_de_30procentregeling1/beschikking_geldigheid_en_toetsen_voorwaarden"
        },
        "nl_2025_box_1_rates" => {
          title: "Belastingdienst: provisional assessment rates and credits 2025",
          authority_name: "Belastingdienst",
          country_code: "NL",
          jurisdiction: "Netherlands",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.belastingdienst.nl/wps/wcm/connect/nl/voorlopige-aanslag/content/voorlopige-aanslag-tarieven-en-heffingskortingen?cid=cpc%3A2023_9_59"
        },
        "nl_2025_general_tax_credit" => {
          title: "Belastingdienst: general tax credit table 2025",
          authority_name: "Belastingdienst",
          country_code: "NL",
          jurisdiction: "Netherlands",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.belastingdienst.nl/wps/wcm/connect/bldcontentnl/belastingdienst/prive/inkomstenbelasting/heffingskortingen_boxen_tarieven/heffingskortingen/algemene_heffingskorting/tabel-algemene-heffingskorting-2025"
        },
        "nl_2025_labour_tax_credit" => {
          title: "Belastingdienst: labour tax credit table 2025",
          authority_name: "Belastingdienst",
          country_code: "NL",
          jurisdiction: "Netherlands",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.belastingdienst.nl/wps/wcm/connect/bldcontentnl/belastingdienst/prive/inkomstenbelasting/heffingskortingen_boxen_tarieven/heffingskortingen/arbeidskorting/tabel-arbeidskorting-2025"
        },
        "nl_2025_self_employed_deduction" => {
          title: "Belastingdienst: self-employed deduction 2025",
          authority_name: "Belastingdienst",
          country_code: "NL",
          jurisdiction: "Netherlands",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.belastingdienst.nl/wps/wcm/connect/bldcontentnl/belastingdienst/zakelijk/winst/inkomstenbelasting/verandering_inkomstenbelasting_vorige_jaren/veranderingen-inkomstenbelasting-2025/ondernemersaftrek-2025/zelfstandigenaftrek-2025"
        },
        "nl_2025_mkb_profit_exemption" => {
          title: "Belastingdienst: SME profit exemption 2025",
          authority_name: "Belastingdienst",
          country_code: "NL",
          jurisdiction: "Netherlands",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.belastingdienst.nl/wps/wcm/connect/bldcontentnl/belastingdienst/zakelijk/winst/inkomstenbelasting/verandering_inkomstenbelasting_vorige_jaren/veranderingen-inkomstenbelasting-2025/mkb-winstvrijstelling-2025"
        },
        "nl_2025_zvw_rates" => {
          title: "Belastingdienst: werkgeversheffing Zvw or own Zvw contribution",
          authority_name: "Belastingdienst",
          country_code: "NL",
          jurisdiction: "Netherlands",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.belastingdienst.nl/wps/wcm/connect/bldcontentnl/belastingdienst/prive/werk_en_inkomen/zorgverzekeringswet/bijdrage_zorgverzekeringswet/tabel_werkgeversheffing_zvw_of_bijdrage_zvw/"
        },
        "nl_2025_expat_scheme_conditions" => {
          title: "Belastingdienst: Expat Scheme conditions and salary thresholds",
          authority_name: "Belastingdienst",
          country_code: "NL",
          jurisdiction: "Netherlands",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.belastingdienst.nl/wps/wcm/connect/nl/buitenland/content/ik-kom-in-nederland-werken-30-procent-regeling-aanvragen"
        },
        "nl_2025_expat_scheme_cap" => {
          title: "Belastingdienst: Expat Scheme maximum tax-free reimbursement 2025",
          authority_name: "Belastingdienst",
          country_code: "NL",
          jurisdiction: "Netherlands",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.belastingdienst.nl/wps/wcm/connect/bldcontenten/belastingdienst/business/payroll_taxes/you_are_not_established_in_the_netherlands_are_you_required_to_withhold_payroll_taxes/when_you_are_going_to_withhold_payroll_taxes/etraterritorial_costs_and_the_30percent-facility/content_of_the_facility/content_of_the_facility"
        }
      }.freeze

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
        })
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
          }
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
    end
  end
end
