import React from "react";

export default function MetricCard({ label, tone = "default", value }) {
  return (
    <article className={`metric-card metric-card--${tone}`}>
      <span className="metric-label">{label}</span>
      <strong className="metric-value">{value}</strong>
    </article>
  );
}
