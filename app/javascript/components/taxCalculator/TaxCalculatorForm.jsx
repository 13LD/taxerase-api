import React from "react";
import { ageBracketOptions, disabilityLevelOptions, salaryPeriodOptions } from "./options";
import CurrencyField from "./fields/CurrencyField";
import SegmentedControl from "./fields/SegmentedControl";
import SelectField from "./fields/SelectField";

export default function TaxCalculatorForm({
  childrenCount,
  childrenCountNumber,
  childrenCountOptions,
  childrenUnderThreeCount,
  childrenUnderThreeOptions,
  deductibleExpenses,
  errors,
  grossIncome,
  incomeLabel,
  isCalculating,
  isSupportedRegime,
  onAgeBracketChange,
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
  periodLabel,
  profileOptions,
  salaryPeriod,
  selectedCategory,
  selectedRegime,
  selectedRegion,
  selectedTaxYear,
  showDeductibleExpenses,
  taxYearOptions,
  regionOptions,
  ageBracket,
  disabilityLevel
}) {
  return (
    <form className="calculator-form" onSubmit={onSubmit}>
      <div className="field-row">
        <SelectField
          label="Tax year"
          onChange={onTaxYearChange}
          options={taxYearOptions.map((year) => ({ value: String(year), label: String(year) }))}
          value={String(selectedTaxYear)}
        />

        <SelectField
          label="Region"
          onChange={onRegionChange}
          options={regionOptions.map((region) => ({
            value: region.region,
            label: region.region
          }))}
          value={selectedRegion}
        />
      </div>

      <SegmentedControl
        label="Tax profile"
        onChange={onCategoryChange}
        options={profileOptions}
        value={selectedCategory}
      />

      <div className="field-row field-row--three">
        <SelectField
          label="Taxpayer age"
          onChange={onAgeBracketChange}
          options={ageBracketOptions}
          value={ageBracket}
        />

        <SelectField
          label="Children"
          onChange={onChildrenCountChange}
          options={childrenCountOptions}
          value={childrenCount}
        />

        <SelectField
          disabled={childrenCountNumber === 0}
          label="Children under 3"
          onChange={onChildrenUnderThreeChange}
          options={childrenUnderThreeOptions}
          value={childrenUnderThreeCount}
        />
      </div>

      <SelectField
        label="Taxpayer disability"
        onChange={onDisabilityLevelChange}
        options={disabilityLevelOptions}
        value={disabilityLevel}
      />

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
