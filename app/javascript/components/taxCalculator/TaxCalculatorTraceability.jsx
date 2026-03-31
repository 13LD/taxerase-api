import React from "react";
import SourceLink from "./SourceLink";

export default function TaxCalculatorTraceability({ assumptionItems, displayedSources }) {
  return (
    <section className="liquid-card assumptions-card">
      <div className="section-head">
        <div>
          <p className="section-kicker">Calculation context</p>
          <h2>Assumptions and official sources</h2>
        </div>
      </div>

      <div className="assumption-list">
        {assumptionItems.map((assumption) => (
          <p key={assumption}>{assumption}</p>
        ))}
      </div>

      <div className="source-list">
        {displayedSources.map((source) => (
          <SourceLink key={`${source.href}-${source.usage_type}`} source={source} />
        ))}
      </div>
    </section>
  );
}
