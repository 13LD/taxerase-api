module Taxerase
  module Seeds
    class AndorraTaxRules < BaseCountryTaxRules
      LIVE_YEARS = [ 2024, 2025, 2026 ].freeze
      REGIME_KEYS = %w[employee_andorra self_employed_andorra].freeze

      SHARED_PARAMETERS = {
        "income_tax_rate" => 0.10,
        "irpf_rate" => 0.10,
        "personal_minimum_base" => 24_000,
        "personal_minimum_disability" => 30_000,
        "personal_reduction_default" => 24_000,
        "personal_reduction_disability" => 30_000,
        "personal_reduction_spouse_without_income" => 40_000,
        "dependent_reduction" => 750,
        "family_member_disability_extra" => 375,
        "mortgage_interest_credit_rate" => 0.25,
        "mortgage_interest_credit_cap" => 1_000,
        "pension_contribution_reduction_cap" => 5_000,
        "pension_contribution_income_rate_cap" => 0.30,
        "earned_income_bonus_rate" => 0.50,
        "earned_income_bonus_cap" => 800
      }.freeze

      SOURCE_DEFINITIONS = {
        "ad_irpf_rate" => {
          title: "Govern d'Andorra: Quin % hauré de pagar?",
          authority_name: "Govern d'Andorra",
          country_code: "AD",
          jurisdiction: "Andorra",
          source_type: "guidance",
          url: "https://www.govern.ad/ca/l/4191537"
        },
        "ad_irpf_reductions" => {
          title: "Govern d'Andorra: Quines reduccions puc obtenir en funció de la meva situació personal, familiar i econòmica?",
          authority_name: "Govern d'Andorra",
          country_code: "AD",
          jurisdiction: "Andorra",
          source_type: "guidance",
          url: "https://www.govern.ad/ca/l/4191244"
        },
        "ad_irpf_work_deduction" => {
          title: "Govern d'Andorra: De les rendes íntegres del treball i en concepte d’altres despeses, quines quantitats em puc deduir?",
          authority_name: "Govern d'Andorra",
          country_code: "AD",
          jurisdiction: "Andorra",
          source_type: "guidance",
          url: "https://www.govern.ad/ca/l/4191480"
        },
        "ad_irpf_spouse_phase_in" => {
          title: "Govern d'Andorra: spouse-income phase-in for the personal minimum",
          authority_name: "Govern d'Andorra",
          country_code: "AD",
          jurisdiction: "Andorra",
          source_type: "guidance",
          url: "https://www.govern.ad/ca/l/4190956"
        },
        "ad_irpf_habitual_home_investment" => {
          title: "Govern d'Andorra: habitual-home investment reduction",
          authority_name: "Govern d'Andorra",
          country_code: "AD",
          jurisdiction: "Andorra",
          source_type: "guidance",
          url: "https://www.govern.ad/ca/l/4191296"
        },
        "ad_irpf_activity_income" => {
          title: "Govern d'Andorra: Com es determina la base de tributació de l’impost?",
          authority_name: "Govern d'Andorra",
          country_code: "AD",
          jurisdiction: "Andorra",
          source_type: "guidance",
          url: "https://www.govern.ad/ca/l/4191408"
        },
        "ad_cass_employee_rates" => {
          title: "CASS: Cobertura sanitària i incorporació al món laboral",
          authority_name: "Caixa Andorrana de Seguretat Social",
          country_code: "AD",
          jurisdiction: "Andorra",
          source_type: "guidance",
          url: "https://www.cass.ad/sites/default/files/documentsvaris/CASS_Triptic_Cobertura%20sanitaria_pro_02_interactiu.pdf"
        },
        "ad_2024_self_employed_social_security" => {
          title: "CASS: own-account contribution bases and quotas (2024)",
          authority_name: "Caixa Andorrana de Seguretat Social",
          country_code: "AD",
          jurisdiction: "Andorra",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://www.cass.ad/cotitzacions-del-treballadors-per-compte-propi2024"
        },
        "ad_2025_self_employed_social_security" => {
          title: "CASS: own-account contribution bases and quotas (2025)",
          authority_name: "Caixa Andorrana de Seguretat Social",
          country_code: "AD",
          jurisdiction: "Andorra",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.cass.ad/base-de-cotitzacio-de-persona-que-realitza-una-activitat-compte-propi"
        },
        "ad_2026_self_employed_social_security" => {
          title: "CASS: own-account contribution base complement guidance (2026)",
          authority_name: "Caixa Andorrana de Seguretat Social",
          country_code: "AD",
          jurisdiction: "Andorra",
          source_type: "guidance",
          tax_year: 2026,
          url: "https://www.cass.ad/sites/default/files/arxius/CASS_COMPLEMENT%20ART99%20COMPTE%20PROPI%20fitxa%2002-02-2026.pdf"
        },
        "ad_cass_under_35_special_regime" => {
          title: "CASS: special regime for people under 35 in the first 24 months of own-account activity",
          authority_name: "Caixa Andorrana de Seguretat Social",
          country_code: "AD",
          jurisdiction: "Andorra",
          source_type: "guidance",
          url: "https://www.cass.ad/regims-especials"
        },
        "ad_2024_housing_rent_support" => {
          title: "Govern d'Andorra: 2024 housing-rent support conditions",
          authority_name: "Govern d'Andorra",
          country_code: "AD",
          jurisdiction: "Andorra",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://www.govern.ad/ca/w/el-govern-prorroga-la-flexibilitzacio-dels-ajuts-a-l-habitatge-de-lloguer-durant-el-2024-1"
        },
        "ad_2025_housing_rent_support" => {
          title: "Govern d'Andorra: 2025 housing-rent support conditions",
          authority_name: "Govern d'Andorra",
          country_code: "AD",
          jurisdiction: "Andorra",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.govern.ad/ca/w/es-modifica-el-reglament-de-les-prestacions-economiques-dels-serveis-socials-i-sociosanitaris"
        },
        "ad_2026_housing_rent_support" => {
          title: "Govern d'Andorra: 2026 housing-rent support and youth emancipation programs",
          authority_name: "Govern d'Andorra",
          country_code: "AD",
          jurisdiction: "Andorra",
          source_type: "guidance",
          tax_year: 2026,
          url: "https://www.govern.ad/ca/tematiques/ajuts-i-subvencions/llar-i-habitatge-de-lloguer"
        }
      }.freeze

      def country_code
        "AD"
      end

      def country_name
        "Andorra"
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
          key: "employee_andorra",
          name: "Resident employee - Andorra",
          tax_year:,
          category: "employee",
          region: "Andorra",
          description: "Resident employee in Andorra with employee CASS contributions, the 3% work-income deduction, personal minimum relief, and basic family reductions."
        )

        replace_brackets!(regime, "income_tax", [ [ nil, 0.10 ] ])
        replace_parameters!(regime, SHARED_PARAMETERS.merge(
          "calculation_method" => Taxerase::Andorra::EmployeeCalculator::CALCULATION_METHOD,
          "employee_social_security_rate" => 0.065,
          "work_expense_rate" => 0.03,
          "work_expense_cap" => 2_500
        ).merge(housing_support_parameters(tax_year)))
        replace_source_usages!(regime, [
          { source_key: "ad_irpf_rate", usage_type: "income_tax", label: "IRPF rate" },
          { source_key: "ad_irpf_reductions", usage_type: "deduction", label: "Personal and family reductions" },
          { source_key: "ad_irpf_spouse_phase_in", usage_type: "deduction_spouse_phase_in", label: "Spouse-income phase-in for the personal minimum" },
          { source_key: "ad_irpf_habitual_home_investment", usage_type: "housing_tax_credit", label: "Habitual-home mortgage investment credit" },
          { source_key: "ad_irpf_work_deduction", usage_type: "deduction_work_income", label: "Work-income deduction" },
          { source_key: housing_support_source_key(tax_year), usage_type: "housing_support", label: "Housing rent support program", notes: "Informational support program shown separately from IRPF and CASS totals." },
          { source_key: "ad_cass_employee_rates", usage_type: "social_security", label: "Employee CASS contribution rate" }
        ])
      end

      def seed_self_employed_regime(country, tax_year)
        regime = build_regime(
          country:,
          key: "self_employed_andorra",
          name: "Standard self-employed - Andorra",
          tax_year:,
          category: "self_employed",
          region: "Andorra",
          description: "Resident self-employed natural person in Andorra with documented business expenses, source-backed CASS own-account base ratios, under-35 special-regime support, and source-backed IRPF household reductions."
        )

        replace_brackets!(regime, "income_tax", [ [ nil, 0.10 ] ])
        replace_parameters!(regime, SHARED_PARAMETERS.merge(
          "calculation_method" => Taxerase::Andorra::SelfEmployedCalculator::CALCULATION_METHOD,
          "self_employed_social_security_rate" => 0.22,
          "monthly_average_salary" => average_monthly_salary(tax_year),
          "minimum_monthly_salary" => minimum_monthly_salary(tax_year),
          "self_employed_base_ratio_tier_1_threshold" => 12_000,
          "self_employed_base_ratio_tier_1" => 0.50,
          "self_employed_base_ratio_tier_2_threshold" => 18_000,
          "self_employed_base_ratio_tier_2" => 0.625,
          "self_employed_base_ratio_tier_3_threshold" => 24_000,
          "self_employed_base_ratio_tier_3" => 0.75,
          "self_employed_base_ratio_tier_4_threshold" => 40_000,
          "self_employed_base_ratio_tier_4" => 1.0,
          "self_employed_base_ratio_tier_5_threshold" => 50_000,
          "self_employed_base_ratio_tier_5" => 1.25,
          "self_employed_base_ratio_tier_6" => 1.375,
          "under_35_special_base_min_salary_ratio" => 0.55,
          "under_35_special_first_year_rate" => 0.10,
          "under_35_special_second_year_rate" => 0.22
        ).merge(housing_support_parameters(tax_year)))
        replace_source_usages!(regime, [
          { source_key: "ad_irpf_rate", usage_type: "income_tax", label: "IRPF rate" },
          { source_key: "ad_irpf_reductions", usage_type: "deduction", label: "Personal and family reductions" },
          { source_key: "ad_irpf_spouse_phase_in", usage_type: "deduction_spouse_phase_in", label: "Spouse-income phase-in for the personal minimum" },
          { source_key: "ad_irpf_habitual_home_investment", usage_type: "housing_tax_credit", label: "Habitual-home mortgage investment credit" },
          { source_key: "ad_irpf_activity_income", usage_type: "deduction_activity_income", label: "Business-activity income rules" },
          { source_key: "ad_#{tax_year}_self_employed_social_security", usage_type: "social_security", label: "Self-employed CASS standard contribution base" },
          { source_key: "ad_cass_under_35_special_regime", usage_type: "social_security_special", label: "Under-35 special CASS regime" },
          { source_key: housing_support_source_key(tax_year), usage_type: "housing_support", label: "Housing rent support program", notes: "Informational support program shown separately from IRPF and CASS totals." }
        ])
      end

      def housing_support_parameters(tax_year)
        case tax_year
        when 2024
          {
            "housing_rent_support_standard_rate" => 0.35,
            "housing_rent_support_priority_rate" => 0.40,
            "housing_rent_support_residency_years" => 3,
            "housing_rent_support_income_cap_multiple_lecs" => 1.3
          }
        else
          {
            "housing_rent_support_standard_rate" => 0.30,
            "housing_rent_support_priority_rate" => 0.35,
            "housing_rent_support_residency_years" => 5,
            "housing_rent_support_income_cap_multiple_lecs" => 1.2
          }
        end
      end

      def housing_support_source_key(tax_year)
        "ad_#{tax_year}_housing_rent_support"
      end

      def average_monthly_salary(tax_year)
        {
          2024 => 2_426.70,
          2025 => 2_560.99,
          2026 => 2_672.52
        }.fetch(tax_year)
      end

      def minimum_monthly_salary(tax_year)
        {
          2024 => 1_376.27,
          2025 => 1_447.33,
          2026 => 1_525.33
        }.fetch(tax_year)
      end
    end
  end
end
