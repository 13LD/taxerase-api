import React from "react";
import MetricCard from "./MetricCard";

export default function TaxCalculatorResults({ detailCards, headlineMetrics }) {
  const showDetailCards = detailCards.length > 0;

  return (
    <section className="liquid-card results-card">
      <div className="section-head">
        <div>
          <p className="section-kicker">Tax results</p>
          <h2>Net income and tax breakdown</h2>
        </div>
      </div>

      <div className="metric-grid">
        {headlineMetrics.map((metric) => (
          <MetricCard
            key={metric.label}
            label={metric.label}
            tone={metric.tone}
            value={metric.value}
          />
        ))}
      </div>

      {showDetailCards ? (
        <div className="detail-grid">
          {detailCards.map((card) => (
            <MetricCard key={card.label} label={card.label} value={card.value} />
          ))}
        </div>
      ) : null}
    </section>
  );
}
