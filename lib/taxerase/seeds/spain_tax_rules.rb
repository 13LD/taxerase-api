module Taxerase
  module Seeds
    class SpainTaxRules < BaseCountryTaxRules
      tax_rule_data = load_country_tax_data("spain")
      FORAL_RESEARCH_REGIONS = deep_symbolize_keys(tax_rule_data.fetch("foral_research_regions")).freeze
      RESEARCH_YEARS = tax_rule_data.fetch("research_years").freeze
      LIVE_COMMON_REGIME_YEARS = tax_rule_data.fetch("live_common_regime_years").freeze
      SOURCE_DEFINITIONS = source_definitions_from(tax_rule_data.fetch("source_definitions")).freeze
      SPECIAL_INBOUND_WORKER_BRACKETS = tax_rule_data.fetch("special_inbound_worker_brackets").freeze
      COMPANY_BRACKETS = tax_rule_data.fetch("company_brackets").freeze

      private

      def country_code
        "ES"
      end

      def country_name
        "Spain"
      end

      def source_definitions
        SOURCE_DEFINITIONS
      end

      def expected_regime_keys_by_year
        {
          2024 => expected_regime_keys_for(2024),
          2025 => expected_regime_keys_for(2025),
          2026 => expected_regime_keys_for(2026)
        }
      end

      def seed_country(country)
        purge_obsolete_regimes!(country)
        seed_live_regimes(country)
        seed_foral_research_regimes(country)
        seed_beckham_regimes(country)
        seed_company_regime(country)
      end

      def purge_obsolete_regimes!(country)
        expected_keys_by_year = expected_regime_keys_by_year
        expected_regime_ids = expected_keys_by_year.flat_map do |tax_year, keys|
          TaxRegime.for_country_year(country:, tax_year:).where(key: keys).pluck(:id)
        end

        TaxRegime
          .for_country(country)
          .where.not(id: expected_regime_ids)
          .find_each(&:destroy!)
      end

      def seed_live_regimes(country)
        LIVE_COMMON_REGIME_YEARS.each do |tax_year|
          region_catalog_for(tax_year)::COMMON_REGIME_REGIONS.each do |region|
            seed_employee_regime(country, tax_year, region)
            seed_self_employed_regime(country, tax_year, region)
          end
        end
      end

      def seed_beckham_regimes(country)
        LIVE_COMMON_REGIME_YEARS.each do |tax_year|
          region_catalog_for(tax_year)::COMMON_REGIME_REGIONS.each do |region|
            seed_beckham_regime(country, tax_year, region)
          end
        end
      end

      def seed_employee_regime(country, tax_year, region_config)
        region_catalog = region_catalog_for(tax_year)
        regime = build_regime(
          country:,
          key: regime_key_for("employee", region_config[:key]),
          name: "Resident employee - #{region_config[:name]}",
          tax_year:,
          category: "employee",
          region: region_config[:name],
          description: "Resident salaried employee in #{region_config[:name]} under the general IRPF regime."
        )

        replace_parameters!(regime, employee_parameters_for(tax_year:, region_config:))
        replace_brackets!(regime, "state_irpf", region_catalog::STATE_IRPF_BRACKETS)
        replace_brackets!(regime, "regional_irpf", region_config[:regional_brackets])
        replace_source_usages!(regime, employee_source_usages_for(tax_year))
      end

      def seed_self_employed_regime(country, tax_year, region_config)
        region_catalog = region_catalog_for(tax_year)
        regime = build_regime(
          country:,
          key: regime_key_for("self_employed", region_config[:key]),
          name: "Resident self-employed - #{region_config[:name]}",
          tax_year:,
          category: "self_employed",
          region: region_config[:name],
          description: "Resident self-employed person in #{region_config[:name]} under direct estimation simplified."
        )

        replace_parameters!(regime, self_employed_parameters_for(tax_year:, region_config:))
        replace_brackets!(regime, "state_irpf", region_catalog::STATE_IRPF_BRACKETS)
        replace_brackets!(regime, "regional_irpf", region_config[:regional_brackets])
        replace_range_brackets!(regime, "self_employed_social_security_bands", self_employed_social_security_bands_for(tax_year))
        replace_source_usages!(regime, self_employed_source_usages_for(tax_year))
      end

      def seed_foral_research_regimes(country)
        RESEARCH_YEARS.each do |tax_year|
          all_region_catalog.each do |region|
            next if live_common_regime_year?(tax_year, region[:key])

            %w[employee self_employed].each do |category|
              regime = build_regime(
                country:,
                key: regime_key_for(category, region[:key]),
                name: "Resident #{category.tr('_', ' ')} - #{region[:name]}",
                tax_year: tax_year,
                category: category,
                region: region[:name],
                description: research_description_for(region:, tax_year:)
              )

              replace_parameters!(
                regime,
                {
                  "calculation_method" => "research_pending"
                }
              )
              replace_source_usages!(regime, research_source_usages_for(region_key: region[:key], tax_year:, category:))
            end
          end
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

        replace_parameters!(regime, { "calculation_method" => "research_pending" })
        replace_brackets!(regime, "corporate_income", COMPANY_BRACKETS)
        replace_source_usages!(regime, [])
      end

      def seed_beckham_regime(country, tax_year, region_config)
        regime = build_regime(
          country:,
          key: beckham_key_for(region_config[:key]),
          name: "Beckham Law - #{region_config[:name]}",
          tax_year: tax_year,
          category: "special_regime",
          region: region_config[:name],
          description: "Beckham Law / Article 93 for eligible inbound workers. Employment income is taxed at national non-resident rates instead of the ordinary resident regional IRPF scale, generally for the arrival year plus five more years."
        )

        replace_parameters!(regime, beckham_parameters_for(tax_year))
        replace_brackets!(regime, "employment_income", SPECIAL_INBOUND_WORKER_BRACKETS)
        replace_source_usages!(regime, beckham_source_usages_for(tax_year))
      end

      def regime_key_for(category, region_key)
        Taxerase::Spain2025::RegionCatalog.regime_key(category:, region_key:)
      end

      def beckham_key_for(region_key)
        Taxerase::Spain2025::RegionCatalog.regime_key(category: "beckham", region_key: region_key)
      end

      def common_region_catalog
        Taxerase::Spain2025::RegionCatalog::COMMON_REGIME_REGIONS.map do |region|
          {
            key: region[:key],
            name: region[:name],
            region_type: "common"
          }
        end
      end

      def all_region_catalog
        @all_region_catalog ||= common_region_catalog + FORAL_RESEARCH_REGIONS.map { |region| region.merge(region_type: "foral") }
      end

      def live_common_regime_year?(tax_year, region_key)
        LIVE_COMMON_REGIME_YEARS.include?(tax_year) && common_region_catalog.any? { |region| region[:key] == region_key }
      end

      def research_description_for(region:, tax_year:)
        if region[:region_type] == "foral"
          "#{region[:name]} is a foral jurisdiction. This #{tax_year} regime is stored as research and still needs a dedicated calculator formula."
        else
          "#{region[:name]} is included for Spain #{tax_year} coverage, but this year remains in research status and still needs a dedicated calculator dataset."
        end
      end

      def research_source_usages_for(region_key:, tax_year:, category:)
        return foral_source_usages_for(region_key, tax_year) if foral_region_key?(region_key)

        []
      end

      def region_catalog_for(tax_year)
        case tax_year
        when 2024
          Taxerase::Spain2024::RegionCatalog
        when 2025
          Taxerase::Spain2025::RegionCatalog
        else
          raise ArgumentError, "No common-region catalog is defined for Spain #{tax_year}"
        end
      end

      def employee_parameters_for(tax_year:, region_config:)
        base = {
          "calculation_method" => Taxerase::Spain::CommonRegimeEmployeeCalculator::CALCULATION_METHOD,
          "gross_work_income_deduction" => 2000,
          "state_taxpayer_minimum" => region_catalog_for(tax_year)::STATE_TAXPAYER_MINIMUM,
          "regional_taxpayer_minimum" => region_config[:regional_taxpayer_minimum]
        }.merge(common_personal_family_minimum_parameters)

        case tax_year
        when 2024
          base.merge(
            "monthly_min_contribution_base" => 1323.00,
            "monthly_max_contribution_base" => 4720.50,
            "employee_social_security_rate" => 0.0647,
            "employee_solidarity_rate" => 0,
            "work_income_adjustment_mode" => "net_income_reduction_2024",
            "work_income_reduction_max" => 7302,
            "work_income_reduction_full_threshold" => 14_852,
            "work_income_reduction_first_phase_threshold" => 17_673.52,
            "work_income_reduction_phase_out_threshold" => 19_747.50,
            "work_income_reduction_first_phase_rate" => 1.75,
            "work_income_reduction_second_phase_base" => 2364.34,
            "work_income_reduction_second_phase_rate" => 1.14
          )
        when 2025
          base.merge(
            "monthly_min_contribution_base" => 1381.20,
            "monthly_max_contribution_base" => 4909.50,
            "employee_social_security_rate" => 0.0648,
            "employee_solidarity_rate" => 0.0092,
            "work_income_adjustment_mode" => "tax_credit_2025",
            "low_income_deduction_max" => 340,
            "low_income_deduction_full_threshold" => 16_576,
            "low_income_deduction_phase_out_threshold" => 18_276,
            "low_income_deduction_phase_out_rate" => 0.2
          )
        else
          raise ArgumentError, "Unsupported employee seed year #{tax_year}"
        end
      end

      def self_employed_parameters_for(tax_year:, region_config:)
        base = {
          "calculation_method" => Taxerase::Spain::CommonRegimeSelfEmployedCalculator::CALCULATION_METHOD,
          "state_taxpayer_minimum" => region_catalog_for(tax_year)::STATE_TAXPAYER_MINIMUM,
          "regional_taxpayer_minimum" => region_config[:regional_taxpayer_minimum],
          "self_employed_social_security_generic_expense_rate" => 0.07,
          "difficult_to_justify_deduction_rate" => 0.05,
          "difficult_to_justify_deduction_cap" => 2000,
          "home_office_supply_deduction_rate" => 0.30,
          "modules_net_income_rate" => 0.30,
          "reta_reduced_monthly_quota" => 80,
          "reta_reduced_special_following_monthly_quota" => 160,
          "family_collaborator_reta_discount_rate" => 0.50,
          "corporate_self_employed_reta_uplift_rate" => 0.10,
          "corporate_self_employed_min_base" => 1000,
          "pluriactivity_refund_rate" => 0.50,
          "pluriactivity_refund_cap_rate" => 0.50
        }.merge(common_personal_family_minimum_parameters)

        case tax_year
        when 2024
          base.merge(
            "self_employed_social_security_rate" => 0.313,
            "pluriactivity_refund_threshold" => 16_030.82
          )
        when 2025
          base.merge(
            "self_employed_social_security_rate" => 0.314,
            "pluriactivity_refund_threshold" => 16_672.66
          )
        else
          raise ArgumentError, "Unsupported self-employed seed year #{tax_year}"
        end
      end

      def beckham_parameters_for(tax_year)
        case tax_year
        when 2024
          {
            "calculation_method" => Taxerase::Spain::BeckhamLawCalculator::CALCULATION_METHOD,
            "monthly_min_contribution_base" => 1323.00,
            "monthly_max_contribution_base" => 4720.50,
            "employee_social_security_rate" => 0.0647
          }
        when 2025
          {
            "calculation_method" => Taxerase::Spain::BeckhamLawCalculator::CALCULATION_METHOD,
            "monthly_min_contribution_base" => 1381.20,
            "monthly_max_contribution_base" => 4909.50,
            "employee_social_security_rate" => 0.0648
          }
        else
          raise ArgumentError, "Unsupported Beckham Law seed year #{tax_year}"
        end
      end

      def self_employed_social_security_bands_for(tax_year)
        case tax_year
        when 2024
          Taxerase::Spain2024::RegionCatalog::RETA_2024_BANDS
        when 2025
          Taxerase::Spain2025::RegionCatalog::RETA_2025_BANDS
        else
          raise ArgumentError, "Unsupported self-employed band year #{tax_year}"
        end
      end

      def common_personal_family_minimum_parameters
        {
          "taxpayer_age_65_increment" => 1150,
          "taxpayer_age_75_increment" => 1400,
          "first_descendant_minimum" => 2400,
          "second_descendant_minimum" => 2700,
          "third_descendant_minimum" => 4000,
          "fourth_and_next_descendant_minimum" => 4500,
          "descendant_under_three_minimum" => 2800,
          "ascendant_minimum" => 1150,
          "ascendant_over_75_increment" => 1400,
          "taxpayer_disability_33_minimum" => 3000,
          "taxpayer_disability_65_minimum" => 9000,
          "taxpayer_disability_support_increment" => 3000,
          "ascendant_disability_33_minimum" => 3000,
          "ascendant_disability_65_minimum" => 9000,
          "ascendant_disability_support_increment" => 3000,
          "joint_filing_married_reduction" => 3400,
          "joint_filing_single_parent_reduction" => 2150,
          "professional_fee_deduction_cap" => 500,
          "legal_defense_deduction_cap" => 300,
          "disabled_worker_expense" => 3500,
          "disabled_worker_high_expense" => 7750,
          "geographic_mobility_expense" => 2000,
          "maternity_monthly_deduction" => 100,
          "nursery_deduction_cap" => 1000,
          "large_family_general_deduction" => 1200,
          "large_family_special_deduction" => 2400,
          "large_family_extra_child_deduction" => 600,
          "single_parent_two_children_deduction" => 1200,
          "family_disability_deduction" => 1200,
          "spouse_disability_deduction" => 1200
        }
      end

      def employee_source_usages_for(tax_year)
        case tax_year
        when 2024
          [
            { source_key: "es_2024_state_irpf", usage_type: "state_irpf", label: "AEAT: 2024 state IRPF scale" },
            { source_key: "es_2024_regional_irpf", usage_type: "regional_irpf", label: "AEAT: 2024 regional IRPF scales" },
            { source_key: "es_2024_taxpayer_minimums", usage_type: "taxpayer_minimums", label: "AEAT: 2024 taxpayer minimums by community" },
            { source_key: "es_2024_employee_expenses", usage_type: "employee_expenses", label: "AEAT: 2024 deductible employee work expenses" },
            { source_key: "es_2024_work_income_reduction", usage_type: "work_income_reduction", label: "AEAT: 2024 work-income reduction" },
            { source_key: "es_2024_ss_employee_rates", usage_type: "employee_social_security_rates", label: "Seguridad Social: 2024 employee rates" },
            { source_key: "es_2024_ss_order", usage_type: "employee_social_security_mei", label: "BOE: 2024 Social Security order and MEI rate" },
            { source_key: "es_2024_ss_employee_bases", usage_type: "employee_social_security_bases", label: "Seguridad Social: 2024 contribution bases" }
          ]
        when 2025
          [
            { source_key: "es_2025_state_irpf", usage_type: "state_irpf", label: "AEAT: 2025 state IRPF scale" },
            { source_key: "es_2025_regional_irpf", usage_type: "regional_irpf", label: "AEAT: 2025 regional IRPF scales" },
            { source_key: "es_2025_taxpayer_minimums", usage_type: "taxpayer_minimums", label: "AEAT: taxpayer minimums by community" },
            { source_key: "es_2025_employee_expenses", usage_type: "employee_expenses", label: "AEAT: deductible employee work expenses" },
            { source_key: "es_2025_work_income_deduction", usage_type: "work_income_deduction", label: "AEAT: 2025 work-income deduction" },
            { source_key: "es_2025_ss_employee_rates", usage_type: "employee_social_security_rates", label: "Seguridad Social: employee rates" },
            { source_key: "es_2025_ss_employee_bases", usage_type: "employee_social_security_bases", label: "Seguridad Social: contribution bases" }
          ]
        else
          raise ArgumentError, "Unsupported employee source year #{tax_year}"
        end
      end

      def self_employed_source_usages_for(tax_year)
        case tax_year
        when 2024
          [
            { source_key: "es_2024_state_irpf", usage_type: "state_irpf", label: "AEAT: 2024 state IRPF scale" },
            { source_key: "es_2024_regional_irpf", usage_type: "regional_irpf", label: "AEAT: 2024 regional IRPF scales" },
            { source_key: "es_2024_taxpayer_minimums", usage_type: "taxpayer_minimums", label: "AEAT: 2024 taxpayer minimums by community" },
            { source_key: "es_2024_direct_estimation", usage_type: "direct_estimation", label: "AEAT: 2024 difficult-to-justify deduction rule" },
            { source_key: "es_2024_reta_summary", usage_type: "reta_bands", label: "Seguridad Social: 2024 RETA bases and rates" }
          ]
        when 2025
          [
            { source_key: "es_2025_state_irpf", usage_type: "state_irpf", label: "AEAT: 2025 state IRPF scale" },
            { source_key: "es_2025_regional_irpf", usage_type: "regional_irpf", label: "AEAT: 2025 regional IRPF scales" },
            { source_key: "es_2025_taxpayer_minimums", usage_type: "taxpayer_minimums", label: "AEAT: taxpayer minimums by community" },
            { source_key: "es_2025_direct_estimation", usage_type: "direct_estimation", label: "AEAT: direct estimation simplified" },
            { source_key: "es_2025_ss_reta_summary", usage_type: "reta_bands", label: "Seguridad Social: 2025 RETA bases and rates" },
            { source_key: "es_2025_ss_reta_net_returns", usage_type: "reta_net_returns", label: "Seguridad Social: 7% net returns rule" }
          ]
        else
          raise ArgumentError, "Unsupported self-employed source year #{tax_year}"
        end
      end

      def beckham_source_usages_for(tax_year)
        case tax_year
        when 2024
          [
            { source_key: "es_2024_beckham_overview", usage_type: "overview", label: "AEAT: Article 93 overview 2024" },
            { source_key: "es_2024_beckham_tax_scale", usage_type: "employment_income", label: "AEAT: Article 93 employment tax scale 2024" },
            { source_key: "es_2024_beckham_model_151", usage_type: "filing", label: "AEAT: Modelo 151 special regime filing" },
            { source_key: "es_2024_ss_employee_rates", usage_type: "employee_social_security_rates", label: "Seguridad Social: 2024 employee rates" },
            { source_key: "es_2024_ss_order", usage_type: "employee_social_security_mei", label: "BOE: 2024 Social Security order and MEI rate" },
            { source_key: "es_2024_ss_employee_bases", usage_type: "employee_social_security_bases", label: "Seguridad Social: 2024 contribution bases" }
          ]
        when 2025
          [
            { source_key: "es_2025_beckham_overview", usage_type: "overview", label: "AEAT: Article 93 overview" },
            { source_key: "es_2025_beckham_tax_scale", usage_type: "employment_income", label: "AEAT: Article 93 employment tax scale 2025" },
            { source_key: "es_2025_beckham_model_149", usage_type: "option", label: "AEAT: Modelo 149 option for the special regime" },
            { source_key: "es_2025_beckham_model_151", usage_type: "filing", label: "AEAT: Modelo 151 special regime filing" },
            { source_key: "es_2025_ss_employee_rates", usage_type: "employee_social_security_rates", label: "Seguridad Social: employee rates" },
            { source_key: "es_2025_ss_employee_bases", usage_type: "employee_social_security_bases", label: "Seguridad Social: contribution bases" }
          ]
        else
          raise ArgumentError, "Unsupported Beckham Law source year #{tax_year}"
        end
      end

      def foral_region_key?(region_key)
        FORAL_RESEARCH_REGIONS.any? { |region| region[:key] == region_key }
      end

      def foral_source_usages_for(region_key, tax_year)
        return [] unless tax_year == 2024

        case region_key
        when "alava"
          [
            { source_key: "alava_2024_renta_faq", usage_type: "overview", label: "Araba: renta 2024 FAQ and tariff overview" }
          ]
        when "bizkaia"
          [
            { source_key: "bizkaia_2024_irpf_education", usage_type: "overview", label: "Bizkaia: IRPF summary and minoration overview" }
          ]
        when "gipuzkoa"
          [
            { source_key: "gipuzkoa_2024_irpf_109", usage_type: "overview", label: "Gipuzkoa: deductions and tariff table" }
          ]
        when "navarre"
          [
            { source_key: "navarre_2024_tariff", usage_type: "tariff", label: "Navarre: IRPF tariff table" },
            { source_key: "navarre_2024_personal_family", usage_type: "personal_family_deductions", label: "Navarre: personal and family deductions" },
            { source_key: "navarre_2024_work_deduction", usage_type: "work_deduction", label: "Navarre: labor income deduction rule" }
          ]
        else
          []
        end
      end

      def expected_regime_keys_for(tax_year)
        keys = all_region_catalog.flat_map do |region|
          [
            regime_key_for("employee", region[:key]),
            regime_key_for("self_employed", region[:key])
          ]
        end

        keys += common_region_catalog.map { |region| beckham_key_for(region[:key]) } if LIVE_COMMON_REGIME_YEARS.include?(tax_year)
        keys += %w[corporate_income_general] if tax_year == 2025
        keys
      end
    end
  end
end
