import React from "react";
import CurrencyField from "./fields/CurrencyField";
import TaxComparisonGraphic from "./TaxComparisonGraphic";
import SegmentedControl from "./fields/SegmentedControl";
import SelectField from "./fields/SelectField";
import { formatCurrency, formatPercentage } from "./formatters";

function formatMetricValue(metric, value) {
  if (metric.value_type === "percentage_points") return formatPercentage(value);
  return formatCurrency(value, metric.display_currency_code);
}

function formatDeltaValue(metric, value) {
  const sign = value > 0 ? "+" : "";

  if (metric.value_type === "percentage_points") {
    return `${sign}${Number(value || 0).toFixed(2)}%`;
  }

  return `${sign}${formatCurrency(value, metric.display_currency_code)}`;
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

function ComparisonMetricCell({ localCurrencyCode, localValue, metric, value }) {
  const showLocalValue =
    metric.value_type === "currency" &&
    metric.converted_from_local &&
    localCurrencyCode &&
    localCurrencyCode !== metric.display_currency_code;

  return (
    <div className="comparison-table__value">
      <strong>{formatMetricValue(metric, value)}</strong>
      {showLocalValue ? (
        <span className="comparison-table__local">
          Local {formatCurrency(localValue, localCurrencyCode)}
        </span>
      ) : null}
    </div>
  );
}

export default function TaxComparisonCard({
  comparisonContextLabel,
  countryDefaultsNote,
  deductibleExpenses,
  deductibleExpensesLabel,
  errors,
  fxReference,
  graphicCopy,
  grossIncome,
  incomeLabel,
  inputCurrencyCode,
  inputCurrencyOptions,
  leftCountryCode,
  leftCountryOptions,
  leftRegion,
  leftRegionOptions,
  onCategoryChange,
  onDeductibleExpensesChange,
  onGrossIncomeChange,
  onInputCurrencyChange,
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
  unavailableMessage,
  usesEuroNormalization
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
          hint="Aligns both sides to the same employment or self-employed calculation shape."
          label="Tax profile"
          onChange={onCategoryChange}
          options={profileOptions}
          value={selectedCategory}
        />

        <CurrencyField
          currencyCode={inputCurrencyCode}
          hint="Shared pre-tax income used as the starting point for both country calculations."
          label={incomeLabel}
          onChange={onGrossIncomeChange}
          value={grossIncome}
        />

        {inputCurrencyOptions.length > 1 ? (
          <SelectField
            hint="Defines the currency for shared comparison inputs before any normalization or local display."
            label="Input currency"
            onChange={onInputCurrencyChange}
            options={inputCurrencyOptions.map((currencyOption) => ({
              value: currencyOption.code,
              label: currencyOption.name
            }))}
            value={inputCurrencyCode}
          />
        ) : null}

        {showDeductibleExpenses ? (
          <CurrencyField
            currencyCode={inputCurrencyCode}
            hint="Shared business costs used only by country profiles that accept actual self-employed expenses."
            label={deductibleExpensesLabel}
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
            hint="Sets the first jurisdiction's source set, currency, rates, and available regional options."
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
            hint="Applies regional tax differences to the first jurisdiction when more than one region exists."
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
            hint="Sets the second jurisdiction's source set, currency, rates, and available regional options."
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
            hint="Applies regional tax differences to the second jurisdiction when more than one region exists."
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
        Comparing {comparisonContextLabel} tax outcomes using the latest shared supported tax year
        {taxYear ? `: ${taxYear}.` : "."} Other personal relief inputs stay on the standard default
        profile for each country.
        {countryDefaultsNote ? ` ${countryDefaultsNote}` : null}
        {usesEuroNormalization && fxReference ? (
          <>
            {" "}Shared income inputs are interpreted in {inputCurrencyCode}. Mixed-currency
            comparison table metrics are normalized to EUR using exchange rates from {fxReference.rate_date}.
          </>
        ) : null}
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
          comparisonCurrencyCode={summaryMetrics.find((metric) => metric.value_type === "currency")?.display_currency_code || inputCurrencyCode}
          graphicCopy={graphicCopy}
          leftLabel={leftLabel}
          rightLabel={rightLabel}
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
                <ComparisonMetricCell
                  localCurrencyCode={metric.left_local_currency_code}
                  localValue={metric.left_local_value}
                  metric={metric}
                  value={metric.left_value}
                />
                <ComparisonMetricCell
                  localCurrencyCode={metric.right_local_currency_code}
                  localValue={metric.right_local_value}
                  metric={metric}
                  value={metric.right_value}
                />
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
