import React from "react";
import TaxCalculatorForm from "./taxCalculator/TaxCalculatorForm";
import TaxComparisonCard from "./taxCalculator/TaxComparisonCard";
import TaxCalculatorResults from "./taxCalculator/TaxCalculatorResults";
import TaxCalculatorTraceability from "./taxCalculator/TaxCalculatorTraceability";
import { resolveCountryCalculatorConfig } from "./taxCalculator/countries";
import useTaxCalculatorEngine from "./taxCalculator/useTaxCalculatorEngine";
import useTaxComparisonEngine from "./taxCalculator/useTaxComparisonEngine";

export default function CountryCalculatorApp(props = {}) {
  const {
    country,
    country_options: countryOptions,
    comparison_catalog: comparisonCatalog,
    tax_year_options: taxYearOptions,
    default_tax_regime_key: defaultTaxRegimeKey,
    regime_options: regimeOptions,
    default_input: defaultInput,
    initial_result: initialResult
  } = props;

  const calculatorConfig = resolveCountryCalculatorConfig(country?.code);
  const formConfig = calculatorConfig.formConfig || {};
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
  const { comparisonProps } = useTaxComparisonEngine({
    comparisonCatalog: comparisonCatalog || [],
    currentCountryCode: country?.code || "",
    defaultGrossIncome: defaultInput?.gross_income
  });

  function handleCountryChange(event) {
    const nextCountryCode = event.target.value;
    const nextUrl = new URL(window.location.href);

    nextUrl.searchParams.set("country", nextCountryCode);
    window.location.assign(nextUrl.toString());
  }

  return (
    <section className="experience-grid">
      <div className="experience-grid__full-width">
        <TaxComparisonCard {...comparisonProps} />
      </div>

      <div className="glass-stack">
        <section className="liquid-card calculator-card">
          <div className="section-head section-head--calculator">
            <p className="section-kicker">{calculatorConfig.sectionKicker}</p>

            <div className="section-head__title-row">
              <h2>{selectedRegime?.name || calculatorConfig.fallbackTitle}</h2>
            </div>
          </div>

          <TaxCalculatorForm
            {...formProps}
            ageBracketOptions={formConfig.ageBracketOptions || []}
            ageFieldHint={formConfig.ageFieldHint}
            countryOptions={countryOptions || []}
            onCountryChange={handleCountryChange}
            selectedCountryCode={country?.code || ""}
            showAgeField={Boolean(formConfig.showAgeField)}
            showChildrenFields={Boolean(formConfig.showChildrenFields)}
            showDisabilityField={Boolean(formConfig.showDisabilityField)}
          />
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
