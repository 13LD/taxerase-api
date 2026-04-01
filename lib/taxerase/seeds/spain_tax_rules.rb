module Taxerase
  module Seeds
    class SpainTaxRules < BaseCountryTaxRules
      FORAL_RESEARCH_REGIONS = [
        { key: "alava", name: "Alava" },
        { key: "bizkaia", name: "Bizkaia" },
        { key: "gipuzkoa", name: "Gipuzkoa" },
        { key: "navarre", name: "Navarre" }
      ].freeze

      RESEARCH_YEARS = [ 2024, 2025, 2026 ].freeze
      LIVE_COMMON_REGIME_YEARS = [ 2024, 2025 ].freeze

      SOURCE_DEFINITIONS = {
        "es_2025_state_irpf" => {
          title: "AEAT: 2025 state IRPF scale",
          authority_name: "Agencia Tributaria",
          country_code: "ES",
          jurisdiction: "Spain",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/c15-calculo-impuesto-determinacion-cuotas-integras/gravamen-base-liquidable-general/gravamen-estatal.html"
        },
        "es_2025_regional_irpf" => {
          title: "AEAT: 2025 regional IRPF scales",
          authority_name: "Agencia Tributaria",
          country_code: "ES",
          jurisdiction: "Spain",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-ayuda-presentacion/irpf-2025/8-cumplimentacion-irpf/8_4-cuota-integra/8_4_3-gravamen-base-liquidable-general/8_4_3_2-cuota-integra-autonomica.html"
        },
        "es_2025_taxpayer_minimums" => {
          title: "AEAT: 2025 taxpayer minimum comparison by community",
          authority_name: "Agencia Tributaria",
          country_code: "ES",
          jurisdiction: "Spain",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://sede.agenciatributaria.gob.es/Sede/ca_es/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/c14-adecuacion-impuesto-circunstancias-personales/minimo-autonomico-personal-familiar/cuadro-minimos-personales-familiares-estatal-autonomicos.html"
        },
        "es_2025_employee_expenses" => {
          title: "AEAT: deductible employee work expenses",
          authority_name: "Agencia Tributaria",
          country_code: "ES",
          jurisdiction: "Spain",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/c03-rendimientos-trabajo/rendimiento-neto-trabajo-integrar-base-imponible/fase-2-determinacion-rendimiento-neto/gastos-deducibles-articulo-19-ley-irpf.html"
        },
        "es_2025_work_income_deduction" => {
          title: "AEAT: 2025 work-income deduction",
          authority_name: "Agencia Tributaria",
          country_code: "ES",
          jurisdiction: "Spain",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://sede.agenciatributaria.gob.es/Sede/en_gb/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/guia-principales-novedades/deducciones-cuota-liquida-total.html"
        },
        "es_2025_direct_estimation" => {
          title: "AEAT: direct estimation simplified",
          authority_name: "Agencia Tributaria",
          country_code: "ES",
          jurisdiction: "Spain",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://sede.agenciatributaria.gob.es/Sede/irpf/empresarios-individuales-profesionales/regimenes-determinar-rendimiento-actividad/estimacion-directa-simplificada.html?faqId=d01bb6d6877c9710VgnVCM100000dc381e0aRCRD"
        },
        "es_2025_ss_employee_rates" => {
          title: "Seguridad Social: employee rates",
          authority_name: "Seguridad Social",
          country_code: "ES",
          jurisdiction: "Spain",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.seg-social.es/wps/portal/wss/internet/Trabajadores/CotizacionRecaudacionTrabajadores/10721/10957/9932/4315/4316?changeLanguage=es"
        },
        "es_2025_ss_employee_bases" => {
          title: "Seguridad Social: contribution bases",
          authority_name: "Seguridad Social",
          country_code: "ES",
          jurisdiction: "Spain",
          source_type: "guidance",
          tax_year: 2025,
          url: "https://www.seg-social.es/wps/portal/wss/internet/Trabajadores/CotizacionRecaudacionTrabajadores/10721/10957/9932/4327"
        },
        "es_2025_ss_reta_summary" => {
          title: "Seguridad Social: 2025 RETA bases and rates summary",
          authority_name: "Seguridad Social",
          country_code: "ES",
          jurisdiction: "Spain",
          source_type: "pdf",
          tax_year: 2025,
          url: "https://www.seg-social.es/wps/wcm/connect/wss/18e91bc9-f6c5-4387-b994-51b6a8b71bf4/2021_2025_Tabla%2Bresumen%2Bde%2Bbases%2By%2Btipos%2Bde%2Blos%2Bultimos%2B5%2Ba%C3%B1os.pdf?MOD=AJPERES"
        },
        "es_2025_ss_reta_net_returns" => {
          title: "Seguridad Social: net returns and 7% expense rule",
          authority_name: "Seguridad Social",
          country_code: "ES",
          jurisdiction: "Spain",
          source_type: "faq",
          tax_year: 2025,
          url: "https://www.seg-social.es/wps/portal/wss/internet/FAQ/?temaPregunta=Nuevo+sistema+de+cotizaci%C3%B3n+para+aut%C3%B3nomos+2023&view=FAQs_detalle_tema"
        },
        "es_2024_state_irpf" => {
          title: "AEAT: 2024 state IRPF scale",
          authority_name: "Agencia Tributaria",
          country_code: "ES",
          jurisdiction: "Spain",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2024/c15-calculo-impuesto-determinacion-cuotas-integras/gravamen-base-liquidable-general/gravamen-estatal.html"
        },
        "es_2024_regional_irpf" => {
          title: "AEAT: 2024 regional IRPF scales",
          authority_name: "Agencia Tributaria",
          country_code: "ES",
          jurisdiction: "Spain",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2024/c15-calculo-impuesto-determinacion-cuotas-integras/gravamen-base-liquidable-general/gravamen-autonomico.html"
        },
        "es_2024_taxpayer_minimums" => {
          title: "AEAT: 2024 taxpayer minimum comparison by community",
          authority_name: "Agencia Tributaria",
          country_code: "ES",
          jurisdiction: "Spain",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2024/c14-adecuacion-impuesto-circunstancias-personales/minimo-autonomico-personal-familiar/cuadro-minimos-personales-familiares-estatal-autonomicos.html"
        },
        "es_2024_employee_expenses" => {
          title: "AEAT: deductible employee work expenses",
          authority_name: "Agencia Tributaria",
          country_code: "ES",
          jurisdiction: "Spain",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://sede.agenciatributaria.gob.es/Sede/gl_es/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2024/c03-rendimientos-trabajo/rendimiento-neto-trabajo-integrar-base-imponible/fase-2-determinacion-rendimiento-neto/gastos-deducibles-articulo-19-ley-irpf.html"
        },
        "es_2024_work_income_reduction" => {
          title: "AEAT: 2024 work-income reduction",
          authority_name: "Agencia Tributaria",
          country_code: "ES",
          jurisdiction: "Spain",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2024/c03-rendimientos-trabajo/rendimiento-neto-trabajo-integrar-base-imponible/fase-3-determinacion-rendimiento-neto-reducido.html"
        },
        "es_2024_ss_employee_rates" => {
          title: "Seguridad Social: employee rates",
          authority_name: "Seguridad Social",
          country_code: "ES",
          jurisdiction: "Spain",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://www.seg-social.es/wps/portal/wss/internet/Trabajadores/CotizacionRecaudacionTrabajadores/10721/10957/9932/4315/4316?changeLanguage=es"
        },
        "es_2024_ss_employee_bases" => {
          title: "Seguridad Social: contribution bases",
          authority_name: "Seguridad Social",
          country_code: "ES",
          jurisdiction: "Spain",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://www.seg-social.es/wps/portal/wss/internet/Trabajadores/CotizacionRecaudacionTrabajadores/10721/10957/9932/4327"
        },
        "es_2024_ss_order" => {
          title: "BOE: Orden PJC/51/2024 cotización 2024",
          authority_name: "BOE",
          country_code: "ES",
          jurisdiction: "Spain",
          source_type: "law",
          tax_year: 2024,
          url: "https://www.boe.es/buscar/act.php?id=BOE-A-2024-1691"
        },
        "es_2024_reta_summary" => {
          title: "Seguridad Social: 2024 RETA bases and rates summary",
          authority_name: "Seguridad Social",
          country_code: "ES",
          jurisdiction: "Spain",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://www.seg-social.es/descarga/es/Tabla_Autonomo"
        },
        "es_2024_direct_estimation" => {
          title: "AEAT: 2024 simplified direct estimation difficult-to-justify rule",
          authority_name: "Agencia Tributaria",
          country_code: "ES",
          jurisdiction: "Spain",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2024/c07-rendimientos-actividades-economicas-estimacion-directa/fase-1-determinacion-rendimiento-neto/gastos-fiscalmente-deducibles/provisiones.html"
        },
        "alava_2024_renta_faq" => {
          title: "Araba: renta 2024 frequently asked questions",
          authority_name: "Diputación Foral de Álava",
          country_code: "ES",
          jurisdiction: "Alava",
          source_type: "faq",
          tax_year: 2024,
          url: "https://web.araba.eus/es/renta/preguntas-frecuentes"
        },
        "bizkaia_2024_irpf_education" => {
          title: "Bizkaia: IRPF education summary",
          authority_name: "Diputación Foral de Bizkaia",
          country_code: "ES",
          jurisdiction: "Bizkaia",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://www.bizkaia.eus/es/web/educacion-tributaria/impuesto-sobre-la-renta-de-las-personas-fisicas-irpf"
        },
        "gipuzkoa_2024_irpf_109" => {
          title: "Gipuzkoa: deductions and tariff table",
          authority_name: "Diputación Foral de Gipuzkoa",
          country_code: "ES",
          jurisdiction: "Gipuzkoa",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://www.gipuzkoa.eus/es/web/ogasuna/impuestos/modelo/109/2018/bonificaciones-reducciones-deducciones-tabla-gravamen"
        },
        "navarre_2024_tariff" => {
          title: "Navarre: IRPF tariff table",
          authority_name: "Hacienda Foral de Navarra",
          country_code: "ES",
          jurisdiction: "Navarre",
          source_type: "pdf",
          tax_year: 2024,
          url: "https://www.navarra.es/NR/rdonlyres/835C1B7C-4D64-4B78-9554-D7C068B54911/0/Tipos2022.pdf"
        },
        "navarre_2024_personal_family" => {
          title: "Navarre: personal and family deductions",
          authority_name: "Hacienda Foral de Navarra",
          country_code: "ES",
          jurisdiction: "Navarre",
          source_type: "faq",
          tax_year: 2024,
          url: "https://www.navarra.es/home_es/Gobierno%2Bde%2BNavarra/Organigrama/Los%2Bdepartamentos/Economia%2By%2BHacienda/Organigrama/Estructura%2BOrganica/Hacienda/Informacion%2BFiscal/Preguntas%2Bmas%2Bfrecuentes/Impuesto%2Bsobre%2Bla%2Brenta%2Bde%2Blas%2Bpersonas%2Bfisicas/Deducciones%2Bpersonales%2By%2Bfamiliares/cuantia_hijos.htm"
        },
        "navarre_2024_work_deduction" => {
          title: "Navarre: labor income deduction rule",
          authority_name: "Gobierno de Navarra",
          country_code: "ES",
          jurisdiction: "Navarre",
          source_type: "law",
          tax_year: 2024,
          url: "https://www.navarra.es/NR/rdonlyres/25510DCA-1642-4BC5-ACA4-268040A39C9B/0/Modificacionestributariaspara2019.pdf"
        }
      }.freeze

      SPECIAL_INBOUND_WORKER_BRACKETS = [
        [ 600_000, 0.24 ],
        [ nil, 0.47 ]
      ].freeze

      COMPANY_BRACKETS = [
        [ nil, 0.25 ]
      ].freeze

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
        seed_company_regime(country)
        seed_inbound_workers_regime(country)
      end

      def purge_obsolete_regimes!(country)
        expected_keys_by_year = RESEARCH_YEARS.index_with do
          all_region_catalog.flat_map do |region|
            [
              regime_key_for("employee", region[:key]),
              regime_key_for("self_employed", region[:key])
            ]
          end
        end

        country.tax_regimes
          .where(category: %w[employee self_employed])
          .where.not(
            "(tax_year = ? AND key IN (?)) OR (tax_year = ? AND key IN (?)) OR (tax_year = ? AND key IN (?))",
            2024,
            expected_keys_by_year.fetch(2024),
            2025,
            expected_keys_by_year.fetch(2025),
            2026,
            expected_keys_by_year.fetch(2026)
          )
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

      def seed_inbound_workers_regime(country)
        regime = build_regime(
          country:,
          key: "inbound_workers_article_93",
          name: "Inbound workers regime - article 93",
          tax_year: 2025,
          category: "special_regime",
          region: "Spain",
          description: "Special regime applicable to workers displaced to Spain."
        )

        replace_parameters!(regime, { "calculation_method" => "research_pending" })
        replace_brackets!(regime, "employment_income", SPECIAL_INBOUND_WORKER_BRACKETS)
        replace_source_usages!(regime, [])
      end

      def regime_key_for(category, region_key)
        Taxerase::Spain2025::RegionCatalog.regime_key(category:, region_key:)
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
          "difficult_to_justify_deduction_cap" => 2000
        }.merge(common_personal_family_minimum_parameters)

        case tax_year
        when 2024
          base.merge("self_employed_social_security_rate" => 0.313)
        when 2025
          base.merge("self_employed_social_security_rate" => 0.314)
        else
          raise ArgumentError, "Unsupported self-employed seed year #{tax_year}"
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
          "taxpayer_disability_33_minimum" => 3000,
          "taxpayer_disability_65_minimum" => 9000,
          "taxpayer_disability_support_increment" => 3000
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

        if tax_year == 2025
          keys + %w[corporate_income_general inbound_workers_article_93]
        else
          keys
        end
      end
    end
  end
end
