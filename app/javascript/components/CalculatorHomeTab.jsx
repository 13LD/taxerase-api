import React from "react";
import TaxCalculatorForm from "./taxCalculator/TaxCalculatorForm";
import TaxCalculatorResults from "./taxCalculator/TaxCalculatorResults";
import TaxCalculatorTraceability from "./taxCalculator/TaxCalculatorTraceability";
import { resolveCountryCalculatorConfig } from "./taxCalculator/countries";
import useTaxCalculatorEngine from "./taxCalculator/useTaxCalculatorEngine";

function visibleForCategory(setting, selectedCategory) {
  if (Array.isArray(setting)) return setting.includes(selectedCategory);
  return Boolean(setting);
}

export default function CalculatorHomeTab({
  calculatorProps,
  countrySwitchErrors,
  isCountrySwitching,
  onCountryChangeRequest,
  onProfileTypeChangeRequest
}) {
  const {
    country,
    country_options: countryOptions,
    input_currency_options: inputCurrencyOptions,
    tax_year_options: taxYearOptions,
    default_tax_regime_key: defaultTaxRegimeKey,
    regime_options: regimeOptions,
    default_input: defaultInput,
    initial_result: initialResult
  } = calculatorProps;

  const calculatorConfig = resolveCountryCalculatorConfig(country?.code);
  const formConfig = calculatorConfig.formConfig || {};
  const {
    assumptionItems,
    detailCards,
    displayedSources,
    formProps,
    headlineMetrics,
    ruleStatusItems,
    selectedRegime
  } = useTaxCalculatorEngine({
    calculationEndpoint: calculatorConfig.calculationEndpoint,
    countryCurrencyCode: country?.currency_code || "EUR",
    defaultInput,
    defaultTaxRegimeKey,
    inputCurrencyOptions: inputCurrencyOptions || [],
    onCategoryPreferenceChange: onProfileTypeChangeRequest,
    regimeControls: formConfig.regimeControls || [],
    initialResult,
    profileLabels: formConfig.profileLabels || {},
    regimeOptions,
    taxYearOptions
  });

  const combinedErrors = countrySwitchErrors.concat(formProps.errors);

  return (
    <section className="experience-grid calculator-home-tab">
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
            childrenCountHint={formConfig.childrenCountHint}
            childrenUnderThreeHint={formConfig.childrenUnderThreeHint}
            countryOptions={countryOptions || []}
            disabilityFieldHint={formConfig.disabilityFieldHint}
            disabilityOptions={formConfig.disabilityOptions || []}
            errors={combinedErrors}
            isCountrySwitching={isCountrySwitching}
            onCountryChange={(event) => onCountryChangeRequest(event.target.value)}
            selectedCountryCode={country?.code || ""}
            showAgeField={visibleForCategory(formConfig.showAgeField, formProps.selectedCategory)}
            showChildrenCountField={visibleForCategory(formConfig.showChildrenCountField, formProps.selectedCategory)}
            showChildrenUnderThreeField={visibleForCategory(formConfig.showChildrenUnderThreeField, formProps.selectedCategory)}
            showDisabilityField={visibleForCategory(formConfig.showDisabilityField, formProps.selectedCategory)}
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
          ruleStatusItems={ruleStatusItems}
        />
      </div>
    </section>
  );
}
