import React from "react";
import { disabilityLevelOptions, salaryPeriodOptions } from "./options";
import CurrencyField from "./fields/CurrencyField";
import CheckboxField from "./fields/CheckboxField";
import SegmentedControl from "./fields/SegmentedControl";
import SelectField from "./fields/SelectField";

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
  deductibleExpenses,
  disabilityLevel,
  errors,
  grossIncome,
  incomeLabel,
  isCalculating,
  isSupportedRegime,
  onCountryChange,
  onAgeBracketChange,
  onApplyThirtyPercentRulingChange,
  onCategoryChange,
  onChildrenCountChange,
  onChildrenUnderThreeChange,
  onDeductibleExpensesChange,
  onDisabilityLevelChange,
  onGrossIncomeChange,
  onRegionChange,
  onSalaryPeriodChange,
  onSubmit,
  onTaxYearChange,
  onThirtyPercentRulingBasisChange,
  periodLabel,
  profileOptions,
  salaryPeriod,
  showThirtyPercentRulingField,
  selectedCountryCode,
  selectedCategory,
  selectedRegime,
  selectedRegion,
  selectedTaxYear,
  showAgeField,
  showChildrenFields,
  showDeductibleExpenses,
  showDisabilityField,
  taxYearOptions,
  applyThirtyPercentRuling,
  thirtyPercentRulingBasis,
  thirtyPercentRulingBasisOptions,
  thirtyPercentRulingHint,
  regionOptions
}) {
  const showRegionField = regionOptions.length > 1;
  const showThirtyPercentRulingControls = showThirtyPercentRulingField && selectedCategory === "employee";

  return (
    <form className="calculator-form" onSubmit={onSubmit}>
      {countryOptions.length > 1 ? (
        <SelectField
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

      {showAgeField || showChildrenFields ? (
        <div className={`field-row ${showAgeField && showChildrenFields ? "field-row--three" : ""}`.trim()}>
          {showAgeField ? (
            <SelectField
              hint={ageFieldHint}
              label="Taxpayer age"
              onChange={onAgeBracketChange}
              options={ageBracketOptions}
              value={ageBracket}
            />
          ) : null}

          {showChildrenFields ? (
            <SelectField
              label="Children"
              onChange={onChildrenCountChange}
              options={childrenCountOptions}
              value={childrenCount}
            />
          ) : null}

          {showChildrenFields ? (
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

      {showDisabilityField ? (
        <SelectField
          label="Taxpayer disability"
          onChange={onDisabilityLevelChange}
          options={disabilityLevelOptions}
          value={disabilityLevel}
        />
      ) : null}

      {showThirtyPercentRulingControls ? (
        <>
          <CheckboxField
            checked={applyThirtyPercentRuling}
            hint={thirtyPercentRulingHint}
            label="Apply 30% ruling"
            onChange={onApplyThirtyPercentRulingChange}
          />

          {applyThirtyPercentRuling ? (
            <SelectField
              label="30% ruling basis"
              onChange={onThirtyPercentRulingBasisChange}
              options={thirtyPercentRulingBasisOptions}
              value={thirtyPercentRulingBasis}
            />
          ) : null}
        </>
      ) : null}

      <CurrencyField
        label={incomeLabel}
        onChange={onGrossIncomeChange}
        value={grossIncome}
      />

      {showDeductibleExpenses ? (
        <CurrencyField
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
