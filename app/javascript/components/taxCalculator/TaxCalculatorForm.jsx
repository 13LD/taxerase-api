import React from "react";
import { defaultDisabilityLevelOptions, salaryPeriodOptions } from "./options";
import CurrencyField from "./fields/CurrencyField";
import CheckboxField from "./fields/CheckboxField";
import NumberField from "./fields/NumberField";
import SegmentedControl from "./fields/SegmentedControl";
import SelectField from "./fields/SelectField";

function fallbackControlHint(control) {
  if (control.hint) return control.hint;
  if (control.type === "checkbox") {
    return "Turn this on only when the underlying tax condition applies; unchecked leaves that rule out of the estimate.";
  }
  if (control.type === "select") {
    return "This changes which statutory path, eligibility band, or calculation method is applied for the selected year.";
  }
  if (control.type === "currency") {
    return "Enter the annual eligible amount in the selected input currency; keep 0 when the deduction or expense does not apply.";
  }
  if (control.type === "number") {
    return "Enter the count, percentage, days, hours, or kilometres used by this rule; keep 0 when it does not apply.";
  }

  return null;
}

function renderRegimeControl(control, value, onChange, currencyCode) {
  const hint = fallbackControlHint(control);

  if (control.type === "checkbox") {
    return (
      <CheckboxField
        key={control.key}
        checked={Boolean(value)}
        hint={hint}
        label={control.label}
        onChange={(event) => onChange(control.key, event.target.checked)}
      />
    );
  }

  if (control.type === "select") {
    return (
      <SelectField
        key={control.key}
        hint={hint}
        label={control.label}
        onChange={(event) => onChange(control.key, event.target.value)}
        options={control.options}
        value={value}
      />
    );
  }

  if (control.type === "currency") {
    return (
      <CurrencyField
        key={control.key}
        currencyCode={control.currencyCode || currencyCode}
        hint={hint}
        label={control.label}
        onChange={(event) => onChange(control.key, event.target.value)}
        value={value}
      />
    );
  }

  if (control.type === "number") {
    return (
      <NumberField
        key={control.key}
        hint={hint}
        label={control.label}
        max={control.max}
        min={control.min}
        onChange={(event) => onChange(control.key, event.target.value)}
        step={control.step}
        suffix={control.suffix}
        value={value}
      />
    );
  }

  return null;
}

export default function TaxCalculatorForm({
  advancedOptionsEnabled,
  ageBracket,
  ageBracketOptions,
  ageFieldHint,
  childrenCount,
  childrenCountHint = null,
  childrenCountNumber,
  childrenCountOptions,
  childrenUnderThreeCount,
  childrenUnderThreeHint = null,
  childrenUnderThreeOptions,
  countryOptions,
  currencyCode,
  deductibleExpenses,
  disabilityLevel,
  disabilityFieldHint = null,
  disabilityOptions,
  errors,
  grossIncome,
  incomeLabel,
  inputCurrencyCode,
  inputCurrencyOptions,
  isCalculating,
  isCountrySwitching,
  isSupportedRegime,
  onCountryChange,
  onAgeBracketChange,
  onCategoryChange,
  onChildrenCountChange,
  onChildrenUnderThreeChange,
  onDeductibleExpensesChange,
  onDisabilityLevelChange,
  onGrossIncomeChange,
  onInputCurrencyChange,
  onRegionChange,
  onRegimeControlChange,
  onSalaryPeriodChange,
  onSubmit,
  onTaxYearChange,
  periodLabel,
  profileOptions,
  regimeControls,
  regimeControlValues,
  salaryPeriod,
  selectedCountryCode,
  selectedCategory,
  selectedRegime,
  selectedRegion,
  selectedTaxYear,
  showAgeField,
  showChildrenCountField,
  showChildrenUnderThreeField,
  showDeductibleExpenses,
  showDisabilityField,
  showPersonalReliefFields,
  taxYearOptions,
  regionOptions
}) {
  const showRegionField = regionOptions.length > 1;
  const showChildrenFields = showChildrenCountField || showChildrenUnderThreeField;
  const resolvedDisabilityOptions = disabilityOptions?.length
    ? disabilityOptions
    : defaultDisabilityLevelOptions;

  return (
    <form className="calculator-form" onSubmit={onSubmit}>
      {countryOptions.length > 1 ? (
        <SelectField
          disabled={isCountrySwitching}
          hint="Sets the country-specific calculator, official source set, currency defaults, and available tax profiles."
          label="Country"
          onChange={onCountryChange}
          options={countryOptions.map((countryOption) => ({
            value: countryOption.code,
            label: countryOption.name
          }))}
          value={selectedCountryCode}
        />
      ) : null}

      <div className={`field-row ${showRegionField ? "" : "field-row--single"}`.trim()}>
        <SelectField
          hint="Controls which rates, thresholds, credits, contribution caps, and source-backed rules are applied."
          label="Tax year"
          onChange={onTaxYearChange}
          options={taxYearOptions.map((year) => ({ value: String(year), label: String(year) }))}
          value={String(selectedTaxYear)}
        />

        {showRegionField ? (
          <SelectField
            hint="Applies regional tax differences where the country has location-specific rates, deductions, or minimums."
            label="Region"
            onChange={onRegionChange}
            options={regionOptions.map((region) => ({
              value: region.region,
              label: region.region
            }))}
            value={selectedRegion}
          />
        ) : null}
      </div>

      <SegmentedControl
        hint="Changes the calculation path between payroll-style employment income and business-income rules."
        label="Tax profile"
        onChange={onCategoryChange}
        options={profileOptions}
        value={selectedCategory}
      />

      {inputCurrencyOptions.length > 1 ? (
        <SelectField
          hint="Defines the currency for entered amounts; supported calculators convert and display results consistently."
          label="Input currency"
          onChange={onInputCurrencyChange}
          options={inputCurrencyOptions.map((currencyOption) => ({
            value: currencyOption.code,
            label: currencyOption.name
          }))}
          value={inputCurrencyCode}
        />
      ) : null}

      <CurrencyField
        currencyCode={inputCurrencyCode}
        hint="Gross income before tax, credits, deductions, and social-security or contribution effects."
        label={incomeLabel}
        onChange={onGrossIncomeChange}
        value={grossIncome}
      />

      {showDeductibleExpenses ? (
        <CurrencyField
          currencyCode={inputCurrencyCode}
          hint="Business expenses that reduce profit before tax when the selected self-employed method accepts actual costs."
          label="Deductible expenses"
          onChange={onDeductibleExpensesChange}
          value={deductibleExpenses}
        />
      ) : null}

      {advancedOptionsEnabled ? (
        <SegmentedControl
          hint="Determines whether the income amount is used as a yearly value or annualized from a monthly value."
          label={periodLabel}
          onChange={onSalaryPeriodChange}
          options={salaryPeriodOptions}
          value={salaryPeriod}
        />
      ) : null}

      {advancedOptionsEnabled ? regimeControls.map((control) =>
        renderRegimeControl(control, regimeControlValues[control.key], onRegimeControlChange, currencyCode)
      ) : null}

      {showPersonalReliefFields && (showAgeField || showChildrenFields) ? (
        <div
          className={`field-row ${
            [ showAgeField, showChildrenCountField, showChildrenUnderThreeField ].filter(Boolean).length >= 3
              ? "field-row--three"
              : ""
          }`.trim()}
        >
          {showAgeField ? (
            <SelectField
              hint={ageFieldHint || "Affects age-based allowances, credits, contribution rates, and retirement-age rules where supported."}
              label="Taxpayer age"
              onChange={onAgeBracketChange}
              options={ageBracketOptions}
              value={ageBracket}
            />
          ) : null}

          {showChildrenCountField ? (
            <SelectField
              hint={childrenCountHint || "Used for child-related credits, minimums, family allowances, and dependent-based reliefs."}
              label="Children"
              onChange={onChildrenCountChange}
              options={childrenCountOptions}
              value={childrenCount}
            />
          ) : null}

          {showChildrenUnderThreeField ? (
            <SelectField
              disabled={childrenCountNumber === 0}
              hint={childrenUnderThreeHint || "Applies early-childhood relief rules and is capped by the total dependent-children count."}
              label="Children under 3"
              onChange={onChildrenUnderThreeChange}
              options={childrenUnderThreeOptions}
              value={childrenUnderThreeCount}
            />
          ) : null}
        </div>
      ) : null}

      {showPersonalReliefFields && showDisabilityField ? (
        <SelectField
          hint={disabilityFieldHint || "Applies disability-linked allowances, credits, or personal minimum increases where the country supports them."}
          label="Taxpayer disability"
          onChange={onDisabilityLevelChange}
          options={resolvedDisabilityOptions}
          value={disabilityLevel}
        />
      ) : null}

      <button
        className="primary-action"
        type="submit"
        disabled={isCalculating || !selectedRegime || !isSupportedRegime}
      >
        {isCalculating ? "Calculating..." : "Recalculate"}
      </button>

      {!selectedRegime ? (
        <div className="availability-note">
          <p>No regimes are seeded for {selectedTaxYear} yet.</p>
        </div>
      ) : null}

      {errors.length > 0 ? (
        <div className="error-panel">
          {errors.map((error) => (
            <p key={error}>{error}</p>
          ))}
        </div>
      ) : null}
    </form>
  );
}
