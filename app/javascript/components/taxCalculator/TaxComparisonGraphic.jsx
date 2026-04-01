import React from "react";
import { formatCurrency, formatPercentage } from "./formatters";

function metricValue(summaryMetrics, metricKey, valueKey) {
  return summaryMetrics.find((metric) => metric.key === metricKey)?.[valueKey] || 0;
}

function clampPercentage(value) {
  return Math.max(0, Math.min(100, Number(value || 0)));
}

function comparisonCopy({ deductibleExpenses, grossIncome, incomeLabel, showDeductibleExpenses }) {
  const normalizedIncomeLabel = incomeLabel.charAt(0).toLowerCase() + incomeLabel.slice(1);

  if (!showDeductibleExpenses) {
    return {
      introTitle: "Gross income vs tax load",
      introSummary: `Based on ${normalizedIncomeLabel} ${formatCurrency(grossIncome)}.`,
      panelSummary: `${incomeLabel} ${formatCurrency(grossIncome)}`
    };
  }

  return {
    introTitle: "Revenue vs tax load",
    introSummary:
      `Based on ${normalizedIncomeLabel} ${formatCurrency(grossIncome)} and annual deductible expenses ` +
      `${formatCurrency(deductibleExpenses)}.`,
    panelSummary:
      `Revenue ${formatCurrency(grossIncome)} · deductible expenses ${formatCurrency(deductibleExpenses)}`
  };
}

function barData(summaryMetrics, sidePrefix) {
  const taxRate = clampPercentage(
    metricValue(summaryMetrics, "effective_tax_rate", `${sidePrefix}_value`)
  );

  return {
    taxRate,
    netRate: Math.max(0, 100 - taxRate),
    totalTax: metricValue(summaryMetrics, "total_tax", `${sidePrefix}_value`),
    netIncome: metricValue(summaryMetrics, "annual_net_income", `${sidePrefix}_value`)
  };
}

function JurisdictionGraphic({ label, panelSummary, sidePrefix, summaryMetrics }) {
  const { taxRate, netRate, totalTax, netIncome } = barData(summaryMetrics, sidePrefix);

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
          <strong>{formatCurrency(netIncome)}</strong>
        </div>
        <div>
          <span className="mini-label">Total Tax</span>
          <strong>{formatCurrency(totalTax)}</strong>
        </div>
      </div>
    </article>
  );
}

export default function TaxComparisonGraphic({
  deductibleExpenses,
  grossIncome,
  incomeLabel,
  leftLabel,
  rightLabel,
  showDeductibleExpenses,
  summaryMetrics
}) {
  const comparisonDetails = comparisonCopy({
    deductibleExpenses,
    grossIncome,
    incomeLabel,
    showDeductibleExpenses
  });

  return (
    <section className="comparison-graphic">
      <div className="comparison-graphic__intro">
        <p className="section-kicker">Visual comparison</p>
        <h3>{comparisonDetails.introTitle}</h3>
        <p>{comparisonDetails.introSummary}</p>
      </div>

      <div className="comparison-graphic__grid">
        <JurisdictionGraphic
          label={leftLabel}
          panelSummary={comparisonDetails.panelSummary}
          sidePrefix="left"
          summaryMetrics={summaryMetrics}
        />
        <JurisdictionGraphic
          label={rightLabel}
          panelSummary={comparisonDetails.panelSummary}
          sidePrefix="right"
          summaryMetrics={summaryMetrics}
        />
      </div>
    </section>
  );
}
