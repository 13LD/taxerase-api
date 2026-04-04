import React from "react";
import { defaultDisabilityLevelOptions, salaryPeriodOptions } from "./options";
import CurrencyField from "./fields/CurrencyField";
import CheckboxField from "./fields/CheckboxField";
import NumberField from "./fields/NumberField";
import SegmentedControl from "./fields/SegmentedControl";
import SelectField from "./fields/SelectField";

function renderRegimeControl(control, value, onChange, currencyCode) {
  if (control.type === "checkbox") {
    return (
      <CheckboxField
        key={control.key}
        checked={Boolean(value)}
        hint={control.hint}
        label={control.label}
        onChange={(event) => onChange(control.key, event.target.checked)}
      />
    );
  }

  if (control.type === "select") {
    return (
      <SelectField
        key={control.key}
        hint={control.hint}
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
        hint={control.hint}
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
        hint={control.hint}
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
  ageBracket,
  ageBracketOptions,
  ageFieldHint,
  childrenCount,
  childrenCountNumber,
  childrenCountOptions,
  childrenUnderThreeCount,
  childrenUnderThreeOptions,
  countryOptions,
  currencyCode,
  deductibleExpenses,
  disabilityLevel,
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
          label="Tax year"
          onChange={onTaxYearChange}
          options={taxYearOptions.map((year) => ({ value: String(year), label: String(year) }))}
          value={String(selectedTaxYear)}
        />

        {showRegionField ? (
          <SelectField
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
        label="Tax profile"
        onChange={onCategoryChange}
        options={profileOptions}
        value={selectedCategory}
      />

      {inputCurrencyOptions.length > 1 ? (
        <SelectField
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
        label={incomeLabel}
        onChange={onGrossIncomeChange}
        value={grossIncome}
      />

      {showDeductibleExpenses ? (
        <CurrencyField
          currencyCode={inputCurrencyCode}
          label="Deductible expenses"
          onChange={onDeductibleExpensesChange}
          value={deductibleExpenses}
        />
      ) : null}

      <SegmentedControl
        label={periodLabel}
        onChange={onSalaryPeriodChange}
        options={salaryPeriodOptions}
        value={salaryPeriod}
      />

      {regimeControls.map((control) =>
        renderRegimeControl(control, regimeControlValues[control.key], onRegimeControlChange, currencyCode)
      )}

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
              hint={ageFieldHint}
              label="Taxpayer age"
              onChange={onAgeBracketChange}
              options={ageBracketOptions}
              value={ageBracket}
            />
          ) : null}

          {showChildrenCountField ? (
            <SelectField
              label="Children"
              onChange={onChildrenCountChange}
              options={childrenCountOptions}
              value={childrenCount}
            />
          ) : null}

          {showChildrenUnderThreeField ? (
            <SelectField
              disabled={childrenCountNumber === 0}
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
