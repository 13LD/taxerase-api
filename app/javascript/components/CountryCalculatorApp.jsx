import React, { startTransition, useCallback, useEffect, useRef, useState } from "react";
import TaxCalculatorForm from "./taxCalculator/TaxCalculatorForm";
import TaxComparisonCard from "./taxCalculator/TaxComparisonCard";
import TaxCalculatorResults from "./taxCalculator/TaxCalculatorResults";
import TaxCalculatorTraceability from "./taxCalculator/TaxCalculatorTraceability";
import { requestCountryCalculator } from "./taxCalculator/api";
import { resolveCountryCalculatorConfig } from "./taxCalculator/countries";
import useTaxCalculatorEngine from "./taxCalculator/useTaxCalculatorEngine";
import useTaxComparisonEngine from "./taxCalculator/useTaxComparisonEngine";

function CountryCalculatorPanel({
  calculatorProps,
  countrySwitchErrors,
  isCountrySwitching,
  onCountryChangeRequest
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
  const visibleForCategory = (setting, selectedCategory) => {
    if (Array.isArray(setting)) return setting.includes(selectedCategory);
    return Boolean(setting);
  };
  const {
    assumptionItems,
    detailCards,
    displayedSources,
    formProps,
    headlineMetrics,
    selectedRegime
  } = useTaxCalculatorEngine({
    calculationEndpoint: calculatorConfig.calculationEndpoint,
    countryCurrencyCode: country?.currency_code || "EUR",
    defaultInput,
    defaultTaxRegimeKey,
    inputCurrencyOptions: inputCurrencyOptions || [],
    incomeLabels: formConfig.incomeLabels || {},
    regimeControls: formConfig.regimeControls || [],
    initialResult,
    periodLabels: formConfig.periodLabels || {},
    profileLabels: formConfig.profileLabels || {},
    regimeOptions,
    taxYearOptions
  });

  const combinedErrors = countrySwitchErrors.concat(formProps.errors);

  return (
    <>
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
        />
      </div>
    </>
  );
}

function ComparisonPanel({ calculatorProps }) {
  const { comparison_catalog: comparisonCatalog, country, default_input: defaultInput } = calculatorProps;
  const { comparisonProps } = useTaxComparisonEngine({
    comparisonCatalog: comparisonCatalog || [],
    currentCountryCode: country?.code || "",
    defaultGrossIncome: defaultInput?.gross_income
  });

  return (
    <div className="experience-grid__full-width">
      <TaxComparisonCard {...comparisonProps} />
    </div>
  );
}

export default function CountryCalculatorApp(initialProps = {}) {
  const [calculatorProps, setCalculatorProps] = useState(initialProps);
  const [countrySwitchErrors, setCountrySwitchErrors] = useState([]);
  const [isCountrySwitching, setIsCountrySwitching] = useState(false);
  const requestAbortControllerRef = useRef(null);

  useEffect(
    () => () => {
      requestAbortControllerRef.current?.abort();
    },
    []
  );

  const handleCountryChangeRequest = useCallback(
    async (nextCountryCode) => {
      if (!nextCountryCode || nextCountryCode === calculatorProps.country?.code) return;

      requestAbortControllerRef.current?.abort();

      const abortController = new AbortController();
      requestAbortControllerRef.current = abortController;
      setCountrySwitchErrors([]);
      setIsCountrySwitching(true);

      try {
        const response = await requestCountryCalculator({
          countryCode: nextCountryCode,
          signal: abortController.signal
        });
        const payload = await response.json();

        if (abortController.signal.aborted) return;

        if (!response.ok) {
          setCountrySwitchErrors(payload.errors || [ "The calculator could not switch countries." ]);
          setIsCountrySwitching(false);
          return;
        }

        startTransition(() => {
          setCalculatorProps(payload.calculator_props);
        });

        if (payload.page_title) document.title = payload.page_title;

        const nextUrl = new URL(window.location.href);
        nextUrl.searchParams.set("country", nextCountryCode);
        window.history.replaceState({}, "", nextUrl.toString());
        setIsCountrySwitching(false);
      } catch {
        if (abortController.signal.aborted) return;

        setCountrySwitchErrors([ "Network error while switching countries." ]);
        setIsCountrySwitching(false);
      }
    },
    [calculatorProps.country?.code]
  );

  return (
    <section className="experience-grid">
      <ComparisonPanel calculatorProps={calculatorProps} />

      <CountryCalculatorPanel
        key={calculatorProps.country?.code || "calculator"}
        calculatorProps={calculatorProps}
        countrySwitchErrors={countrySwitchErrors}
        isCountrySwitching={isCountrySwitching}
        onCountryChangeRequest={handleCountryChangeRequest}
      />
    </section>
  );
}
