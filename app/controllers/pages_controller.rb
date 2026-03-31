class PagesController < ApplicationController
  def home
    regime_options = Taxerase::Spain2025::CalculationRouter.regime_options
    default_tax_regime_key = Taxerase::Spain2025::CalculationRouter.default_regime_key
    initial_result = Taxerase::Spain2025::CalculationRouter.call(
      gross_income: 60_000,
      salary_period: "YEAR",
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
        salary_period: "YEAR"
      },
      initial_result: initial_result,
      research_tracks: [
        {
          title: "Employed income",
          status: "Live in v1",
          detail: "Interactive estimate for a Spain 2025 salaried employee resident in Madrid with a standard indefinite contract, no dependants, and no extra deductions.",
          href: "https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/c15-calculo-impuesto-determinacion-cuotas-integras/gravamen-base-liquidable-general/gravamen-estatal.html"
        },
        {
          title: "Self-employed",
          status: "Source-backed next",
          detail: "Official AEAT direct-estimation guidance and Seguridad Social RETA brackets are collected for the next calculator slice.",
          href: "https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/c07-rendimientos-actividades-economicas-estimacion-directa.html"
        },
        {
          title: "Companies",
          status: "Source-backed next",
          detail: "Corporate tax baseline is anchored to AEAT's current Impuesto sobre Sociedades guidance.",
          href: "https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-ayuda-presentacion/modelo-200-2018/05-tipo-gravamen/5_02-tipos-impositivos-vigentes.html"
        },
        {
          title: "Special regimes",
          status: "Scoped next",
          detail: "The inbound workers regime under article 93 IRPF is researched and reserved for the next interactive mode.",
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
          label: "AEAT: Madrid 2025 regional scale",
          href: "https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/c15-calculo-impuesto-determinacion-cuotas-integras/gravamen-base-liquidable-general/gravamen-autonomico/comunidad-madrid.html"
        },
        {
          label: "AEAT: Madrid taxpayer minimums",
          href: "https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/c14-adecuacion-impuesto-circunstancias-personales/minimo-autonomico-personal-familiar/comunidad-madrid-importes-minimo-personal-familiar.html"
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
          label: "Seguridad Social: 2025 employee rates",
          href: "https://www.seg-social.es/wps/portal/wss/internet/Trabajadores/CotizacionRecaudacionTrabajadores/10721/10957/9932/4315/4316?changeLanguage=es"
        },
        {
          label: "Seguridad Social: 2025 contribution bases",
          href: "https://www.seg-social.es/wps/portal/wss/internet/Trabajadores/CotizacionRecaudacionTrabajadores/10721/10957/9932/4327"
        }
      ]
    }
  end
end
