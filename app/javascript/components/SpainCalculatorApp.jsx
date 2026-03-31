import React, { startTransition, useMemo, useState } from "react";

const currencyFormatter = new Intl.NumberFormat("en-US", {
  style: "currency",
  currency: "EUR",
  maximumFractionDigits: 2
});

const percentageFormatter = new Intl.NumberFormat("en-US", {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2
});

function MetricCard({ label, value, tone = "default" }) {
  return (
    <article className={`metric-card metric-card--${tone}`}>
      <span className="metric-label">{label}</span>
      <strong className="metric-value">{value}</strong>
    </article>
  );
}

function SourceLink({ source }) {
  return (
    <a className="source-link" href={source.href} target="_blank" rel="noreferrer">
      <span>{source.label}</span>
      <span aria-hidden="true">↗</span>
    </a>
  );
}

function formatCurrency(value) {
  return currencyFormatter.format(Number(value || 0));
}

function formatPercentage(value) {
  return `${percentageFormatter.format(Number(value || 0))}%`;
}

export default function SpainCalculatorApp({
  country,
  default_tax_regime_key: defaultTaxRegimeKey,
  regime_options: regimeOptions,
  default_input: defaultInput,
  initial_result: initialResult,
  research_tracks: researchTracks,
  sources
}) {
  const [taxRegimeKey, setTaxRegimeKey] = useState(defaultTaxRegimeKey);
  const [grossIncome, setGrossIncome] = useState(String(defaultInput.gross_income));
  const [salaryPeriod, setSalaryPeriod] = useState(defaultInput.salary_period);
  const [result, setResult] = useState(initialResult);
  const [status, setStatus] = useState("ready");
  const [errors, setErrors] = useState([]);

  const selectedRegime =
    regimeOptions.find((regime) => regime.key === taxRegimeKey) || regimeOptions[0];
  const isSupportedRegime = Boolean(selectedRegime?.supported);
  const displayStatus = isSupportedRegime ? status : "unavailable";
  const assumptionItems = isSupportedRegime
    ? result.assumptions
    : [
        selectedRegime?.description || "This regime exists in the database.",
        "The rules are stored in PostgreSQL, but the interactive calculator flow is not implemented yet."
      ];

  const headlineMetrics = useMemo(
    () => [
      {
        label: "Annual net income",
        value: formatCurrency(result.breakdown.annual_net_income),
        tone: "primary"
      },
      {
        label: "Monthly net income",
        value: formatCurrency(result.breakdown.monthly_net_income),
        tone: "secondary"
      },
      {
        label: "Effective tax rate",
        value: formatPercentage(result.breakdown.effective_tax_rate),
        tone: "default"
      }
    ],
    [result]
  );

  function handleRegimeChange(event) {
    setTaxRegimeKey(event.target.value);
    setErrors([]);
    setStatus("ready");
  }

  async function handleSubmit(event) {
    event.preventDefault();
    if (!isSupportedRegime) return;

    setStatus("loading");
    setErrors([]);

    try {
      const response = await fetch("/api/v1/spain/salary_calculation", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": document
            .querySelector("meta[name='csrf-token']")
            ?.getAttribute("content")
        },
        body: JSON.stringify({
          calculation: {
            gross_income: grossIncome,
            salary_period: salaryPeriod,
            tax_regime_key: taxRegimeKey
          }
        })
      });

      const payload = await response.json();

      if (!response.ok) {
        setErrors(payload.errors || ["The calculator could not process this request."]);
        setStatus("error");
        return;
      }

      startTransition(() => {
        setResult(payload);
      });
      setStatus("success");
    } catch (_error) {
      setErrors(["Network error while calculating."]);
      setStatus("error");
    }
  }

  return (
    <section className="experience-grid">
      <div className="glass-stack">
        <section className="liquid-card calculator-card">
          <div className="section-head">
            <div>
              <p className="section-kicker">EU tax calculator</p>
              <h2>{selectedRegime?.name || "Spain tax estimate"}</h2>
            </div>
            <span className="status-pill">
              {country.name} · {country.tax_year}
            </span>
          </div>

          <form className="calculator-form" onSubmit={handleSubmit}>
            <label className="field">
              <span className="field-label">Tax regime</span>
              <div className="select-shell">
                <select value={taxRegimeKey} onChange={handleRegimeChange}>
                  {regimeOptions.map((regime) => (
                    <option key={regime.key} value={regime.key}>
                      {regime.name} {regime.supported ? "" : "(Research)"}
                    </option>
                  ))}
                </select>
              </div>
            </label>

            <label className="field">
              <span className="field-label">Gross income</span>
              <div className="currency-input">
                <span>€</span>
                <input
                  type="number"
                  min="0"
                  step="0.01"
                  inputMode="decimal"
                  value={grossIncome}
                  onChange={(event) => setGrossIncome(event.target.value)}
                />
              </div>
            </label>

            <div className="field">
              <span className="field-label">Salary period</span>
              <div className="segmented-control">
                {["YEAR", "MONTH"].map((period) => (
                  <button
                    key={period}
                    className={period === salaryPeriod ? "is-active" : ""}
                    type="button"
                    onClick={() => setSalaryPeriod(period)}
                  >
                    {period === "YEAR" ? "Annual" : "Monthly"}
                  </button>
                ))}
              </div>
            </div>

            <button
              className="primary-action"
              type="submit"
              disabled={status === "loading" || !isSupportedRegime}
            >
              {status === "loading" ? "Calculating..." : "Recalculate"}
            </button>
          </form>

          {!isSupportedRegime ? (
            <div className="availability-note">
              <p>{selectedRegime?.status} only: this regime is already seeded in the database, but its UI and calculation flow are still pending.</p>
            </div>
          ) : null}

          {errors.length > 0 ? (
            <div className="error-panel">
              {errors.map((error) => (
                <p key={error}>{error}</p>
              ))}
            </div>
          ) : null}

        </section>

        <section className="liquid-card tracks-card">
          <div className="section-head">
            <div>
              <p className="section-kicker">Research tracks</p>
              <h2>What is live, what is next</h2>
            </div>
          </div>

          <div className="track-grid">
            {researchTracks.map((track) => (
              <article className="track-card" key={track.title}>
                <div className="track-head">
                  <h3>{track.title}</h3>
                  <span>{track.status}</span>
                </div>
                <p>{track.detail}</p>
                <a href={track.href} target="_blank" rel="noreferrer">
                  Official source ↗
                </a>
              </article>
            ))}
          </div>
        </section>
      </div>

      <div className="glass-stack">
        <section className="liquid-card results-card">
          <div className="section-head">
            <div>
              <p className="section-kicker">Output</p>
              <h2>Transparent tax breakdown</h2>
            </div>
            <span className={`response-state response-state--${displayStatus}`}>{displayStatus}</span>
          </div>

          {isSupportedRegime ? (
            <>
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

              <div className="detail-grid">
                <MetricCard
                  label="Income tax"
                  value={formatCurrency(result.breakdown.annual_income_tax)}
                />
                <MetricCard
                  label="Employee social security"
                  value={formatCurrency(result.breakdown.annual_social_security)}
                />
                <MetricCard label="Total tax" value={formatCurrency(result.breakdown.total_tax)} />
                <MetricCard
                  label="Taxable work income"
                  value={formatCurrency(result.breakdown.taxable_work_income)}
                />
                <MetricCard
                  label="State minimum relief"
                  value={formatCurrency(result.breakdown.state_minimum_relief)}
                />
                <MetricCard
                  label="Madrid minimum relief"
                  value={formatCurrency(result.breakdown.madrid_minimum_relief)}
                />
              </div>
            </>
          ) : (
            <div className="unavailable-state">
              <h3>No live calculator for this regime yet</h3>
              <p>
                The rule records are already in PostgreSQL, but this regime still needs its own
                calculation workflow and result breakdown.
              </p>
            </div>
          )}
        </section>

        <section className="liquid-card assumptions-card">
          <div className="section-head">
            <div>
              <p className="section-kicker">Traceability</p>
              <h2>Assumptions and source anchors</h2>
            </div>
          </div>

          <div className="assumption-list">
            {assumptionItems.map((assumption) => (
              <p key={assumption}>{assumption}</p>
            ))}
          </div>

          <div className="source-list">
            {sources.map((source) => (
              <SourceLink key={source.href} source={source} />
            ))}
          </div>
        </section>
      </div>
    </section>
  );
}
