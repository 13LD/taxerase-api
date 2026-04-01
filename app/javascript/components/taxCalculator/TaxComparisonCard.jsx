import React from "react";
import CurrencyField from "./fields/CurrencyField";
import TaxComparisonGraphic from "./TaxComparisonGraphic";
import SegmentedControl from "./fields/SegmentedControl";
import SelectField from "./fields/SelectField";
import { formatCurrency, formatPercentage } from "./formatters";

function formatMetricValue(metric, value) {
  if (metric.value_type === "percentage_points") return formatPercentage(value);
  return formatCurrency(value);
}

function formatDeltaValue(metric, value) {
  const sign = value > 0 ? "+" : "";

  if (metric.value_type === "percentage_points") {
    return `${sign}${Number(value || 0).toFixed(2)}%`;
  }

  return `${sign}${formatCurrency(value)}`;
}

function deltaTone(metric, value) {
  if (value === 0) return "tie";

  const betterForRight = metric.higher_is_better ? value > 0 : value < 0;
  return betterForRight ? "positive" : "negative";
}

function sideLabel(countryOptions, countryCode, region) {
  const countryName = countryOptions.find((country) => country.code === countryCode)?.name || countryCode;
  return !region || region === countryName ? countryName : `${countryName} · ${region}`;
}

export default function TaxComparisonCard({
  deductibleExpenses,
  errors,
  grossIncome,
  incomeLabel,
  leftCountryCode,
  leftCountryOptions,
  leftRegion,
  leftRegionOptions,
  onCategoryChange,
  onDeductibleExpensesChange,
  onGrossIncomeChange,
  onLeftCountryChange,
  onLeftRegionChange,
  onRightCountryChange,
  onRightRegionChange,
  profileOptions,
  rightCountryCode,
  rightCountryOptions,
  rightRegion,
  rightRegionOptions,
  selectedCategory,
  showDeductibleExpenses,
  status,
  summaryMetrics,
  taxYear,
  unavailableMessage
}) {
  const leftLabel = sideLabel(leftCountryOptions, leftCountryCode, leftRegion);
  const rightLabel = sideLabel(rightCountryOptions, rightCountryCode, rightRegion);

  return (
    <section className="liquid-card comparison-card">
      <div className="section-head">
        <div>
          <p className="section-kicker">Tax comparison</p>
          <h2>Compare two jurisdictions</h2>
        </div>
      </div>

      <div className="comparison-shared-controls">
        <SegmentedControl
          label="Tax profile"
          onChange={onCategoryChange}
          options={profileOptions}
          value={selectedCategory}
        />

        <CurrencyField
          label={incomeLabel}
          onChange={onGrossIncomeChange}
          value={grossIncome}
        />

        {showDeductibleExpenses ? (
          <CurrencyField
            label="Annual deductible expenses"
            onChange={onDeductibleExpensesChange}
            value={deductibleExpenses}
          />
        ) : null}
      </div>

      <div className="comparison-controls">
        <div className="comparison-side">
          <div className="comparison-side__head">
            <p className="comparison-side__eyebrow">First jurisdiction</p>
            <h3>{leftLabel}</h3>
          </div>
          <SelectField
            label="Country"
            onChange={onLeftCountryChange}
            options={leftCountryOptions.map((country) => ({
              value: country.code,
              label: country.name
            }))}
            value={leftCountryCode}
          />
          <SelectField
            disabled={leftRegionOptions.length <= 1}
            label="Region"
            onChange={onLeftRegionChange}
            options={leftRegionOptions.map((region) => ({
              value: region.region,
              label: region.region
            }))}
            value={leftRegion}
          />
        </div>

        <div className="comparison-side">
          <div className="comparison-side__head">
            <p className="comparison-side__eyebrow">Second jurisdiction</p>
            <h3>{rightLabel}</h3>
          </div>
          <SelectField
            label="Country"
            onChange={onRightCountryChange}
            options={rightCountryOptions.map((country) => ({
              value: country.code,
              label: country.name
            }))}
            value={rightCountryCode}
          />
          <SelectField
            disabled={rightRegionOptions.length <= 1}
            label="Region"
            onChange={onRightRegionChange}
            options={rightRegionOptions.map((region) => ({
              value: region.region,
              label: region.region
            }))}
            value={rightRegion}
          />
        </div>
      </div>

      <div className="comparison-context">
        Comparing {selectedCategory === "self_employed" ? "self-employed" : "employed"} tax
        outcomes using the latest shared supported tax year{taxYear ? `: ${taxYear}.` : "."} Other
        personal relief inputs stay on the standard default profile for each country.
      </div>

      {status === "loading" ? <div className="availability-note"><p>Refreshing comparison...</p></div> : null}

      {errors.length > 0 ? (
        <div className="error-panel">
          {errors.map((error) => (
            <p key={error}>{error}</p>
          ))}
        </div>
      ) : null}

      {summaryMetrics.length > 0 ? (
        <TaxComparisonGraphic
          deductibleExpenses={deductibleExpenses}
          grossIncome={grossIncome}
          incomeLabel={incomeLabel}
          leftLabel={leftLabel}
          rightLabel={rightLabel}
          showDeductibleExpenses={showDeductibleExpenses}
          summaryMetrics={summaryMetrics}
        />
      ) : null}

      {summaryMetrics.length > 0 ? (
        <div className="comparison-table">
          <div className="comparison-table__track">
            <div className="comparison-table__head">
              <span>Metric</span>
              <span>{leftLabel}</span>
              <span>{rightLabel}</span>
              <span>Delta</span>
            </div>

            {summaryMetrics.map((metric) => (
              <div className="comparison-table__row" key={metric.key}>
                <span className="comparison-table__metric">{metric.label}</span>
                <strong>{formatMetricValue(metric, metric.left_value)}</strong>
                <strong>{formatMetricValue(metric, metric.right_value)}</strong>
                <span className={`comparison-delta comparison-delta--${deltaTone(metric, metric.delta_value)}`}>
                  {formatDeltaValue(metric, metric.delta_value)}
                </span>
              </div>
            ))}
          </div>
        </div>
      ) : null}

      {status === "unavailable" ? (
        <div className="availability-note">
          <p>{unavailableMessage}</p>
        </div>
      ) : null}
    </section>
  );
}
