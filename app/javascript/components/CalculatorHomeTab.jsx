import React from "react";
import TaxCalculatorForm from "./taxCalculator/TaxCalculatorForm";
import TaxCalculatorResults from "./taxCalculator/TaxCalculatorResults";
import TaxCalculatorTraceability from "./taxCalculator/TaxCalculatorTraceability";
import { authPathWithReturnTo } from "./authPaths";
import { resolveCountryCalculatorConfig } from "./taxCalculator/countries";
import useTaxCalculatorEngine from "./taxCalculator/useTaxCalculatorEngine";

function visibleForCategory(setting, selectedCategory) {
  if (Array.isArray(setting)) return setting.includes(selectedCategory);
  return Boolean(setting);
}

function GuestDetailPrompt({ signInPath }) {
  return (
    <section
      aria-label="Detailed calculation sign in prompt"
      className="liquid-card calculator-auth-note"
    >
      <h3>Sign in for the full breakdown</h3>
      <p>See detailed tax calculations, assumptions, and official-source context for this estimate.</p>
      <a className="secondary-action" href={authPathWithReturnTo(signInPath)}>
        Sign in
      </a>
    </section>
  );
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

  const auth = calculatorProps.auth || {};
  const advancedOptionsEnabled = Boolean(calculatorProps.auth?.signed_in);
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
    advancedOptionsEnabled,
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
            advancedOptionsEnabled={advancedOptionsEnabled}
            onCountryChange={(event) => onCountryChangeRequest(event.target.value)}
            selectedCountryCode={country?.code || ""}
            showAgeField={advancedOptionsEnabled && visibleForCategory(formConfig.showAgeField, formProps.selectedCategory)}
            showChildrenCountField={advancedOptionsEnabled && visibleForCategory(formConfig.showChildrenCountField, formProps.selectedCategory)}
            showChildrenUnderThreeField={advancedOptionsEnabled && visibleForCategory(formConfig.showChildrenUnderThreeField, formProps.selectedCategory)}
            showDisabilityField={advancedOptionsEnabled && visibleForCategory(formConfig.showDisabilityField, formProps.selectedCategory)}
          />
        </section>
      </div>

      <div className="glass-stack">
        <TaxCalculatorResults
          detailCards={advancedOptionsEnabled ? detailCards : []}
          headlineMetrics={headlineMetrics}
        />
        {!advancedOptionsEnabled ? (
          <GuestDetailPrompt signInPath={auth.sign_in_path} />
        ) : null}
      </div>

      {advancedOptionsEnabled ? (
        <div className="experience-grid__full-width">
          <TaxCalculatorTraceability
            assumptionItems={assumptionItems}
            displayedSources={displayedSources}
            ruleStatusItems={ruleStatusItems}
          />
        </div>
      ) : null}
    </section>
  );
}
