class PagesController < ApplicationController
  def home
    regime_options = Taxerase::Spain2025::CalculationRouter.regime_options
    default_tax_regime_key = Taxerase::Spain2025::CalculationRouter.default_regime_key
    initial_result = Taxerase::Spain2025::CalculationRouter.call(
      gross_income: 60_000,
      salary_period: "YEAR",
      deductible_expenses: 0,
      tax_regime_key: default_tax_regime_key
    )

    @calculator_props = {
      country: {
        code: "ES",
        name: "Spain",
        tax_year: 2025
      },
      default_tax_regime_key: default_tax_regime_key,
      regime_options: regime_options,
      default_input: {
        gross_income: 60_000,
        salary_period: "YEAR",
        deductible_expenses: 0
      },
      initial_result: initial_result,
      research_tracks: [
        {
          title: "Employed income",
          status: "Live across Spain",
          detail: "Interactive estimate for resident employees across Spain's common-regime autonomous communities and Ceuta/Melilla using the 2025 regional IRPF scales.",
          href: "https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/c15-calculo-impuesto-determinacion-cuotas-integras/gravamen-base-liquidable-general/gravamen-estatal.html"
        },
        {
          title: "Self-employed",
          status: "Live across Spain",
          detail: "General direct-estimation self-employed calculations now combine AEAT IRPF guidance with the 2025 official RETA contribution bands.",
          href: "https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/c07-rendimientos-actividades-economicas-estimacion-directa.html"
        },
        {
          title: "Companies",
          status: "Source-backed next",
          detail: "Corporate tax baseline is anchored to AEAT's current Impuesto sobre Sociedades guidance.",
          href: "https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-ayuda-presentacion/modelo-200-2018/05-tipo-gravamen/5_02-tipos-impositivos-vigentes.html"
        },
        {
          title: "Foral and special regimes",
          status: "Scoped next",
          detail: "Basque Country, Navarre, and the inbound workers regime under article 93 IRPF still need dedicated province-specific workflows.",
          href: "https://sede.agenciatributaria.gob.es/Sede/eu_es/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/c15-calculo-impuesto-determinacion-cuotas-integras/regimen-fiscal-especial-aplicable-trabajadores.html"
        }
      ],
      assumptions: initial_result[:assumptions],
      sources: [
        {
          label: "AEAT: 2025 state IRPF scale",
          href: "https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/c15-calculo-impuesto-determinacion-cuotas-integras/gravamen-base-liquidable-general/gravamen-estatal.html"
        },
        {
          label: "AEAT: 2025 regional IRPF scales across Spain",
          href: "https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-ayuda-presentacion/irpf-2025/8-cumplimentacion-irpf/8_4-cuota-integra/8_4_3-gravamen-base-liquidable-general/8_4_3_2-cuota-integra-autonomica.html"
        },
        {
          label: "AEAT: 2025 taxpayer minimum comparison by community",
          href: "https://sede.agenciatributaria.gob.es/Sede/ca_es/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/c14-adecuacion-impuesto-circunstancias-personales/minimo-autonomico-personal-familiar/cuadro-minimos-personales-familiares-estatal-autonomicos.html"
        },
        {
          label: "AEAT: deductible employee work expenses",
          href: "https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/c03-rendimientos-trabajo/rendimiento-neto-trabajo-integrar-base-imponible/fase-2-determinacion-rendimiento-neto/gastos-deducibles-articulo-19-ley-irpf.html"
        },
        {
          label: "AEAT: 2025 work-income deduction",
          href: "https://sede.agenciatributaria.gob.es/Sede/en_gb/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/guia-principales-novedades/deducciones-cuota-liquida-total.html"
        },
        {
          label: "AEAT: direct estimation simplified",
          href: "https://sede.agenciatributaria.gob.es/Sede/irpf/empresarios-individuales-profesionales/regimenes-determinar-rendimiento-actividad/estimacion-directa-simplificada.html?faqId=d01bb6d6877c9710VgnVCM100000dc381e0aRCRD"
        },
        {
          label: "Seguridad Social: 2025 RETA bases and rates summary",
          href: "https://www.seg-social.es/wps/wcm/connect/wss/18e91bc9-f6c5-4387-b994-51b6a8b71bf4/2021_2025_Tabla%2Bresumen%2Bde%2Bbases%2By%2Btipos%2Bde%2Blos%2Bultimos%2B5%2Ba%C3%B1os.pdf?MOD=AJPERES"
        },
        {
          label: "Seguridad Social: net returns and 7% general expense rule",
          href: "https://www.seg-social.es/wps/portal/wss/internet/FAQ/?temaPregunta=Nuevo+sistema+de+cotizaci%C3%B3n+para+aut%C3%B3nomos+2023&view=FAQs_detalle_tema"
        }
      ]
    }
  end
end
