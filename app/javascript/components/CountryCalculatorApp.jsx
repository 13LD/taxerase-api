import React from "react";
import TaxCalculatorForm from "./taxCalculator/TaxCalculatorForm";
import TaxCalculatorResults from "./taxCalculator/TaxCalculatorResults";
import TaxCalculatorTraceability from "./taxCalculator/TaxCalculatorTraceability";
import { resolveCountryCalculatorConfig } from "./taxCalculator/countries";
import useTaxCalculatorEngine from "./taxCalculator/useTaxCalculatorEngine";

export default function CountryCalculatorApp(props = {}) {
  const {
    country,
    tax_year_options: taxYearOptions,
    default_tax_regime_key: defaultTaxRegimeKey,
    regime_options: regimeOptions,
    default_input: defaultInput,
    initial_result: initialResult
  } = props;

  const calculatorConfig = resolveCountryCalculatorConfig(country?.code);
  const {
    assumptionItems,
    detailCards,
    displayedSources,
    formProps,
    headlineMetrics,
    selectedRegime
  } = useTaxCalculatorEngine({
    calculationEndpoint: calculatorConfig.calculationEndpoint,
    defaultInput,
    defaultTaxRegimeKey,
    initialResult,
    regimeOptions,
    taxYearOptions
  });

  return (
    <section className="experience-grid">
      <div className="glass-stack">
        <section className="liquid-card calculator-card">
          <div className="section-head section-head--calculator">
            <p className="section-kicker">{calculatorConfig.sectionKicker}</p>

            <div className="section-head__title-row">
              <h2>{selectedRegime?.name || calculatorConfig.fallbackTitle}</h2>
            </div>
          </div>

          <TaxCalculatorForm {...formProps} />
        </section>
      </div>

      <div className="glass-stack">
        <TaxCalculatorResults detailCards={detailCards} headlineMetrics={headlineMetrics} />
      </div>

      <div className="experience-grid__full-width">
        <TaxCalculatorTraceability
          assumptionItems={assumptionItems}
          displayedSources={displayedSources}
        />
      </div>
    </section>
  );
}
