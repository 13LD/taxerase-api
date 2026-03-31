module Taxerase
  module Seeds
    class SpainTaxRules
      FORAL_RESEARCH_REGIONS = [
        { key: "alava", name: "Alava" },
        { key: "bizkaia", name: "Bizkaia" },
        { key: "gipuzkoa", name: "Gipuzkoa" },
        { key: "navarre", name: "Navarre" }
      ].freeze

      RESEARCH_YEARS = [2024, 2025, 2026].freeze

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
        "es_2024_manual_index" => {
          title: "AEAT: 2024 manual index and taxpayer minimums summary",
          authority_name: "Agencia Tributaria",
          country_code: "ES",
          jurisdiction: "Spain",
          source_type: "guidance",
          tax_year: 2024,
          url: "https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2024/esquemas-cuadros-resumenes-incluidos-manual.html"
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
        [600_000, 0.24],
        [nil, 0.47]
      ].freeze

      COMPANY_BRACKETS = [
        [nil, 0.25]
      ].freeze

      def self.call
        new.call
      end

      def call
        ActiveRecord::Base.transaction do
          spain = Country.find_or_initialize_by(code: "ES")
          spain.update!(name: "Spain", currency_code: "EUR")

          purge_obsolete_regimes!(spain)
          seed_live_regimes(spain)
          seed_foral_research_regimes(spain)
          seed_company_regime(spain)
          seed_inbound_workers_regime(spain)
        end
      end

      private

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
        Taxerase::Spain2025::RegionCatalog::COMMON_REGIME_REGIONS.each do |region|
          seed_employee_regime(country, region)
          seed_self_employed_regime(country, region)
        end
      end

      def seed_employee_regime(country, region_config)
        regime = build_regime(
          country:,
          key: regime_key_for("employee", region_config[:key]),
          name: "Resident employee - #{region_config[:name]}",
          tax_year: 2025,
          category: "employee",
          region: region_config[:name],
          description: "Resident salaried employee in #{region_config[:name]} under the general IRPF regime."
        )

        replace_parameters!(
          regime,
          {
            "calculation_method" => Taxerase::Spain::CommonRegimeEmployeeCalculator::CALCULATION_METHOD,
            "gross_work_income_deduction" => 2000,
            "state_taxpayer_minimum" => Taxerase::Spain2025::RegionCatalog::STATE_TAXPAYER_MINIMUM,
            "regional_taxpayer_minimum" => region_config[:regional_taxpayer_minimum],
            "monthly_min_contribution_base" => 1381.20,
            "monthly_max_contribution_base" => 4909.50,
            "employee_social_security_rate" => 0.0648,
            "low_income_deduction_max" => 340,
            "low_income_deduction_full_threshold" => 16_576,
            "low_income_deduction_phase_out_threshold" => 18_276,
            "low_income_deduction_phase_out_rate" => 0.2
          }
        )

        replace_brackets!(regime, "state_irpf", Taxerase::Spain2025::RegionCatalog::STATE_IRPF_BRACKETS)
        replace_brackets!(regime, "regional_irpf", region_config[:regional_brackets])
        replace_source_usages!(
          regime,
          [
            { source_key: "es_2025_state_irpf", usage_type: "state_irpf", label: "AEAT: 2025 state IRPF scale" },
            { source_key: "es_2025_regional_irpf", usage_type: "regional_irpf", label: "AEAT: 2025 regional IRPF scales" },
            { source_key: "es_2025_taxpayer_minimums", usage_type: "taxpayer_minimums", label: "AEAT: taxpayer minimums by community" },
            { source_key: "es_2025_employee_expenses", usage_type: "employee_expenses", label: "AEAT: deductible employee work expenses" },
            { source_key: "es_2025_work_income_deduction", usage_type: "work_income_deduction", label: "AEAT: 2025 work-income deduction" },
            { source_key: "es_2025_ss_employee_rates", usage_type: "employee_social_security_rates", label: "Seguridad Social: employee rates" },
            { source_key: "es_2025_ss_employee_bases", usage_type: "employee_social_security_bases", label: "Seguridad Social: contribution bases" }
          ]
        )
      end

      def seed_self_employed_regime(country, region_config)
        regime = build_regime(
          country:,
          key: regime_key_for("self_employed", region_config[:key]),
          name: "Resident self-employed - #{region_config[:name]}",
          tax_year: 2025,
          category: "self_employed",
          region: region_config[:name],
          description: "Resident self-employed person in #{region_config[:name]} under direct estimation simplified."
        )

        replace_parameters!(
          regime,
          {
            "calculation_method" => Taxerase::Spain::CommonRegimeSelfEmployedCalculator::CALCULATION_METHOD,
            "state_taxpayer_minimum" => Taxerase::Spain2025::RegionCatalog::STATE_TAXPAYER_MINIMUM,
            "regional_taxpayer_minimum" => region_config[:regional_taxpayer_minimum],
            "self_employed_social_security_rate" => 0.314,
            "self_employed_social_security_generic_expense_rate" => 0.07,
            "difficult_to_justify_deduction_rate" => 0.05,
            "difficult_to_justify_deduction_cap" => 2000
          }
        )

        replace_brackets!(regime, "state_irpf", Taxerase::Spain2025::RegionCatalog::STATE_IRPF_BRACKETS)
        replace_brackets!(regime, "regional_irpf", region_config[:regional_brackets])
        replace_range_brackets!(regime, "self_employed_social_security_bands", Taxerase::Spain2025::RegionCatalog::RETA_2025_BANDS)
        replace_source_usages!(
          regime,
          [
            { source_key: "es_2025_state_irpf", usage_type: "state_irpf", label: "AEAT: 2025 state IRPF scale" },
            { source_key: "es_2025_regional_irpf", usage_type: "regional_irpf", label: "AEAT: 2025 regional IRPF scales" },
            { source_key: "es_2025_taxpayer_minimums", usage_type: "taxpayer_minimums", label: "AEAT: taxpayer minimums by community" },
            { source_key: "es_2025_direct_estimation", usage_type: "direct_estimation", label: "AEAT: direct estimation simplified" },
            { source_key: "es_2025_ss_reta_summary", usage_type: "reta_bands", label: "Seguridad Social: 2025 RETA bases and rates" },
            { source_key: "es_2025_ss_reta_net_returns", usage_type: "reta_net_returns", label: "Seguridad Social: 7% net returns rule" }
          ]
        )
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

      def build_regime(country:, key:, name:, tax_year:, category:, region:, description:)
        regime = TaxRegime.find_or_initialize_by(country:, key:, tax_year:)
        regime.update!(
          name:,
          category:,
          region:,
          active: true,
          description:
        )
        regime
      end

      def replace_brackets!(regime, group, rows)
        regime.tax_brackets.where(bracket_group: group).delete_all

        rows.each_with_index do |(upper_bound, rate), index|
          regime.tax_brackets.create!(
            bracket_group: group,
            position: index + 1,
            upper_bound:,
            rate:
          )
        end
      end

      def replace_range_brackets!(regime, group, rows)
        regime.tax_brackets.where(bracket_group: group).delete_all

        rows.each_with_index do |row, index|
          regime.tax_brackets.create!(
            bracket_group: group,
            position: index + 1,
            lower_bound: row[:lower_bound],
            upper_bound: row[:upper_bound],
            base_min: row[:base_min],
            base_max: row[:base_max],
            label: row[:label]
          )
        end
      end

      def replace_parameters!(regime, values)
        regime.tax_parameters.delete_all

        values.each do |key, value|
          if value.is_a?(String)
            regime.tax_parameters.create!(key:, value_text: value)
          else
            regime.tax_parameters.create!(key:, value_decimal: value)
          end
        end
      end

      def replace_source_usages!(regime, usages)
        regime.tax_source_usages.delete_all

        usages.each_with_index do |usage, index|
          regime.tax_source_usages.create!(
            official_tax_source: source_for!(usage[:source_key]),
            usage_type: usage[:usage_type],
            label: usage[:label],
            notes: usage[:notes],
            position: index + 1
          )
        end
      end

      def source_for!(key)
        definition = SOURCE_DEFINITIONS.fetch(key)
        source = OfficialTaxSource.find_or_initialize_by(key: key)
        source.update!(definition)
        source
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
        tax_year == 2025 && common_region_catalog.any? { |region| region[:key] == region_key }
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
        return common_2024_source_usages_for(category) if tax_year == 2024

        []
      end

      def common_2024_source_usages_for(category)
        if category == "self_employed"
          [
            { source_key: "es_2024_state_irpf", usage_type: "state_irpf", label: "AEAT: 2024 state IRPF scale" },
            { source_key: "es_2024_regional_irpf", usage_type: "regional_irpf", label: "AEAT: 2024 regional IRPF scales" },
            { source_key: "es_2024_manual_index", usage_type: "manual_index", label: "AEAT: 2024 manual index and summaries" },
            { source_key: "es_2024_reta_summary", usage_type: "reta_bands", label: "Seguridad Social: 2024 RETA bases and rates" }
          ]
        else
          [
            { source_key: "es_2024_state_irpf", usage_type: "state_irpf", label: "AEAT: 2024 state IRPF scale" },
            { source_key: "es_2024_regional_irpf", usage_type: "regional_irpf", label: "AEAT: 2024 regional IRPF scales" },
            { source_key: "es_2024_manual_index", usage_type: "manual_index", label: "AEAT: 2024 manual index and summaries" }
          ]
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
    end
  end
end
