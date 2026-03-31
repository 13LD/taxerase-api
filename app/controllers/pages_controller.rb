class PagesController < ApplicationController
  def home
    default_tax_year = 2025
    regime_options = Taxerase::Spain::CalculationRouter.regime_options
    default_tax_regime_key = Taxerase::Spain::CalculationRouter.default_regime_key(default_tax_year)
    initial_result = Taxerase::Spain::CalculationRouter.call(
      gross_income: 60_000,
      salary_period: "YEAR",
      tax_year: default_tax_year,
      deductible_expenses: 0,
      tax_regime_key: default_tax_regime_key
    )

    @calculator_props = {
      country: {
        code: "ES",
        name: "Spain"
      },
      tax_year_options: [2024, 2025, 2026],
      default_tax_regime_key: default_tax_regime_key,
      regime_options: regime_options,
      default_input: {
        gross_income: 60_000,
        salary_period: "YEAR",
        tax_year: default_tax_year,
        deductible_expenses: 0
      },
      initial_result: initial_result,
      research_tracks: [
        {
          title: "Common-regime Spain",
          status: "Live for 2025",
          detail: "Common-regime employee and self-employed calculations are live for Spain 2025, with rules loaded from the database and sources mapped to each regime.",
          href: "https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/c15-calculo-impuesto-determinacion-cuotas-integras/gravamen-base-liquidable-general/gravamen-estatal.html"
        },
        {
          title: "Foral territories",
          status: "Source-backed in 2024",
          detail: "Álava, Bizkaia, Gipuzkoa, and Navarre now exist as year-scoped jurisdictions with official source mappings, ready for dedicated calculator formulas.",
          href: "https://web.araba.eus/es/renta/preguntas-frecuentes"
        },
        {
          title: "Year versioning",
          status: "Live in the data model",
          detail: "Calculators now resolve tax regimes by jurisdiction and year instead of a hardcoded Spain2025 namespace, so 2024, 2025, and 2026 can be expanded incrementally.",
          href: "https://sede.agenciatributaria.gob.es/Sede/eu_es/ayuda/manuales-videos-folletos/manuales-practicos/irpf-2025/c15-calculo-impuesto-determinacion-cuotas-integras/regimen-fiscal-especial-aplicable-trabajadores.html"
        }
      ]
    }
  end
end
