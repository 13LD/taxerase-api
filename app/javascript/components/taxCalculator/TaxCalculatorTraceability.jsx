import React from "react";
import SourceLink from "./SourceLink";

function ruleStatusClassName(status) {
  return `rule-status rule-status--${status.status || "needs_review"}`;
}

export default function TaxCalculatorTraceability({
  assumptionItems,
  displayedSources,
  ruleStatusItems = []
}) {
  return (
    <section className="liquid-card assumptions-card">
      <div className="section-head">
        <div>
          <p className="section-kicker">Calculation context</p>
          <h2>Assumptions and official sources</h2>
        </div>
      </div>

      {ruleStatusItems.length > 0 ? (
        <div className="rule-status-list" aria-label="Rule status">
          {ruleStatusItems.map((status) => (
            <article className={ruleStatusClassName(status)} key={status.rule_key || status.message}>
              <div className="rule-status__head">
                <strong>{status.label}</strong>
                <span>{status.status_label || status.status}</span>
              </div>
              <p>{status.message}</p>
            </article>
          ))}
        </div>
      ) : null}

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
