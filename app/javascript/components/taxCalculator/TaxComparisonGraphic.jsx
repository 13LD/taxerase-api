import React from "react";
import { formatCompactCurrency, formatCurrency, formatPercentage } from "./formatters";

function metricValue(summaryMetrics, metricKey, valueKey) {
  return summaryMetrics.find((metric) => metric.key === metricKey)?.[valueKey] || 0;
}

function currencyMetric(summaryMetrics, metricKey, sidePrefix, comparisonCurrencyCode) {
  const metric = summaryMetrics.find((entry) => entry.key === metricKey);
  if (!metric) {
    return {
      comparisonValue: 0,
      comparisonCurrencyCode,
      localCurrencyCode: comparisonCurrencyCode,
      localValue: 0,
      usesLocalDisplay: false
    };
  }

  const localCurrencyCode = metric[`${sidePrefix}_local_currency_code`] || comparisonCurrencyCode;
  const localValue = metric[`${sidePrefix}_local_value`];
  const comparisonValue = metric[`${sidePrefix}_value`];
  const usesLocalDisplay =
    metric.converted_from_local &&
    localCurrencyCode &&
    localCurrencyCode !== metric.display_currency_code;

  return {
    comparisonValue,
    comparisonCurrencyCode: metric.display_currency_code || comparisonCurrencyCode,
    localCurrencyCode,
    localValue,
    usesLocalDisplay
  };
}

function clampPercentage(value) {
  return Math.max(0, Math.min(100, Number(value || 0)));
}

function barData(summaryMetrics, sidePrefix, comparisonCurrencyCode) {
  const taxRate = clampPercentage(
    metricValue(summaryMetrics, "effective_tax_rate", `${sidePrefix}_value`)
  );
  const totalTax = currencyMetric(
    summaryMetrics,
    "total_tax",
    sidePrefix,
    comparisonCurrencyCode
  );
  const netIncome = currencyMetric(
    summaryMetrics,
    "annual_net_income",
    sidePrefix,
    comparisonCurrencyCode
  );

  return {
    taxRate,
    netRate: Math.max(0, 100 - taxRate),
    totalTax,
    netIncome
  };
}

function JurisdictionGraphic({ comparisonCurrencyCode, label, panelSummary, sidePrefix, summaryMetrics }) {
  const { taxRate, netRate, totalTax, netIncome } = barData(
    summaryMetrics,
    sidePrefix,
    comparisonCurrencyCode
  );
  const netIncomeNote = netIncome.usesLocalDisplay
    ? formatCompactCurrency(netIncome.comparisonValue, netIncome.comparisonCurrencyCode)
    : null;
  const totalTaxNote = totalTax.usesLocalDisplay
    ? formatCompactCurrency(totalTax.comparisonValue, totalTax.comparisonCurrencyCode)
    : null;

  return (
    <article className="comparison-graphic__panel">
      <div className="comparison-graphic__head">
        <h3>{label}</h3>
        <p>{panelSummary}</p>
      </div>

      <div className="comparison-graphic__bar-summary">
        <span>Net {formatPercentage(netRate)}</span>
        <span>Tax {formatPercentage(taxRate)}</span>
      </div>

      <div
        aria-label={`${label} gross income split`}
        className="comparison-graphic__bar"
        role="img"
      >
        <div
          className="comparison-graphic__segment comparison-graphic__segment--net"
          style={{ width: `${netRate}%` }}
        >
          <span>Income</span>
        </div>
        <div
          className="comparison-graphic__segment comparison-graphic__segment--tax"
          style={{ width: `${taxRate}%` }}
        >
          <span>Tax</span>
        </div>
      </div>

      <div className="comparison-graphic__stats">
        <div>
          <span className="mini-label">Annual Net Income</span>
          <strong>{formatCurrency(netIncome.localValue, netIncome.localCurrencyCode)}</strong>
          <span
            aria-hidden={netIncomeNote ? undefined : true}
            className={`comparison-graphic__stat-note${netIncomeNote ? "" : " comparison-graphic__stat-note--placeholder"}`}
          >
            {netIncomeNote || "\u00A0"}
          </span>
        </div>
        <div>
          <span className="mini-label">Total Tax</span>
          <strong>{formatCurrency(totalTax.localValue, totalTax.localCurrencyCode)}</strong>
          <span
            aria-hidden={totalTaxNote ? undefined : true}
            className={`comparison-graphic__stat-note${totalTaxNote ? "" : " comparison-graphic__stat-note--placeholder"}`}
          >
            {totalTaxNote || "\u00A0"}
          </span>
        </div>
      </div>
    </article>
  );
}

export default function TaxComparisonGraphic({
  comparisonCurrencyCode,
  graphicCopy,
  leftLabel,
  rightLabel,
  summaryMetrics
}) {
  return (
    <section className="comparison-graphic">
      <div className="comparison-graphic__intro">
        <p className="section-kicker">Visual comparison</p>
        <h3>{graphicCopy.introTitle}</h3>
        <p>{graphicCopy.introSummary}</p>
      </div>

      <div className="comparison-graphic__grid">
        <JurisdictionGraphic
          comparisonCurrencyCode={comparisonCurrencyCode}
          label={leftLabel}
          panelSummary={graphicCopy.panelSummary}
          sidePrefix="left"
          summaryMetrics={summaryMetrics}
        />
        <JurisdictionGraphic
          comparisonCurrencyCode={comparisonCurrencyCode}
          label={rightLabel}
          panelSummary={graphicCopy.panelSummary}
          sidePrefix="right"
          summaryMetrics={summaryMetrics}
        />
      </div>
    </section>
  );
}
