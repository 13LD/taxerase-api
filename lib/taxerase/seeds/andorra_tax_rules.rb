module Taxerase
  module Seeds
    class AndorraTaxRules < BaseCountryTaxRules
      tax_rule_data = load_country_tax_data("andorra")
      LIVE_YEARS = tax_rule_data.fetch("live_years").freeze
      REGIME_KEYS = tax_rule_data.fetch("regime_keys").freeze
      SHARED_PARAMETERS = tax_rule_data.fetch("shared_parameters").freeze
      SOURCE_DEFINITIONS = source_definitions_from(tax_rule_data.fetch("source_definitions")).freeze

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
        ).merge(irpf_reduction_parameters(tax_year)).merge(housing_support_parameters(tax_year)))
        replace_source_usages!(regime, [
          { source_key: "ad_irpf_rate", usage_type: "income_tax", label: "IRPF rate" },
          { source_key: "ad_irpf_reductions", usage_type: "deduction", label: "Personal and family reductions" },
          { source_key: "ad_irpf_spouse_phase_in", usage_type: "deduction_spouse_phase_in", label: "Spouse-income phase-in for the personal minimum" },
          housing_family_reduction_source_usage(tax_year),
          { source_key: "ad_irpf_work_deduction", usage_type: "deduction_work_income", label: "Work-income deduction" },
          { source_key: housing_support_source_key(tax_year), usage_type: "housing_support", label: "Housing rent support program", notes: "Informational support program shown separately from IRPF and CASS totals." },
          { source_key: "ad_cass_employee_rates", usage_type: "social_security", label: "Employee CASS contribution rate" },
          { source_key: "ad_etr_irpf_filing", usage_type: "filing", label: "IRPF filing workflow" },
          { source_key: "ad_etr_tax_catalogue", usage_type: "filing_catalogue", label: "Andorra tax workflow catalogue" },
          { source_key: "ad_etr_igi", usage_type: "indirect_tax", label: "IGI rates and declaration workflow" }
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
        ).merge(irpf_reduction_parameters(tax_year)).merge(housing_support_parameters(tax_year)))
        replace_source_usages!(regime, [
          { source_key: "ad_irpf_rate", usage_type: "income_tax", label: "IRPF rate" },
          { source_key: "ad_irpf_reductions", usage_type: "deduction", label: "Personal and family reductions" },
          { source_key: "ad_irpf_spouse_phase_in", usage_type: "deduction_spouse_phase_in", label: "Spouse-income phase-in for the personal minimum" },
          housing_family_reduction_source_usage(tax_year),
          { source_key: "ad_irpf_activity_income", usage_type: "deduction_activity_income", label: "Business-activity income rules" },
          { source_key: "ad_#{tax_year}_self_employed_social_security", usage_type: "social_security", label: "Self-employed CASS standard contribution base" },
          { source_key: "ad_cass_under_35_special_regime", usage_type: "social_security_special", label: "Under-35 special CASS regime" },
          { source_key: housing_support_source_key(tax_year), usage_type: "housing_support", label: "Housing rent support program", notes: "Informational support program shown separately from IRPF and CASS totals." },
          { source_key: "ad_etr_irpf_filing", usage_type: "filing", label: "IRPF filing workflow" },
          { source_key: "ad_etr_tax_catalogue", usage_type: "filing_catalogue", label: "Andorra tax workflow catalogue" },
          { source_key: "ad_etr_igi", usage_type: "indirect_tax", label: "IGI rates and declaration workflow" }
        ])
      end

      def irpf_reduction_parameters(tax_year)
        if tax_year >= 2025
          {
            "dependent_reduction" => 1_000,
            "family_member_disability_extra" => 500,
            "habitual_home_investment_reduction_rate" => 0.50,
            "habitual_home_investment_reduction_cap" => 5_000,
            "affordable_rental_housing_investment_reduction_rate" => 0.50,
            "affordable_rental_housing_investment_reduction_cap" => 5_000,
            "higher_education_tuition_reduction_cap" => 300
          }
        else
          {
            "dependent_reduction" => 750,
            "family_member_disability_extra" => 375,
            "habitual_home_investment_reduction_rate" => 0.25,
            "habitual_home_investment_reduction_cap" => 1_000,
            "affordable_rental_housing_investment_reduction_rate" => 0,
            "affordable_rental_housing_investment_reduction_cap" => 0,
            "higher_education_tuition_reduction_cap" => 0
          }
        end
      end

      def housing_family_reduction_source_usage(tax_year)
        if tax_year >= 2025
          {
            source_key: "ad_2025_housing_family_reductions",
            usage_type: "housing_family_reductions",
            label: "2025+ housing, dependant, and education reductions"
          }
        else
          {
            source_key: "ad_irpf_habitual_home_investment",
            usage_type: "housing_base_reduction",
            label: "Habitual-home investment base reduction"
          }
        end
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
