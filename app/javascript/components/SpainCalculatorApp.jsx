import React, { startTransition, useEffect, useMemo, useState } from "react";

const currencyFormatter = new Intl.NumberFormat("en-US", {
  style: "currency",
  currency: "EUR",
  maximumFractionDigits: 2
});

const percentageFormatter = new Intl.NumberFormat("en-US", {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2
});

const profileLabels = {
  employee: "Employed",
  self_employed: "Self-employed"
};

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
  const liveRegimes = useMemo(
    () => regimeOptions.filter((regime) => regime.supported),
    [regimeOptions]
  );
  const defaultRegime = useMemo(
    () =>
      liveRegimes.find((regime) => regime.key === defaultTaxRegimeKey) || liveRegimes[0],
    [defaultTaxRegimeKey, liveRegimes]
  );

  const [selectedCategory, setSelectedCategory] = useState(defaultRegime?.category || "employee");
  const [selectedRegion, setSelectedRegion] = useState(defaultRegime?.region || "");
  const [grossIncome, setGrossIncome] = useState(String(defaultInput.gross_income));
  const [deductibleExpenses, setDeductibleExpenses] = useState(
    String(defaultInput.deductible_expenses || 0)
  );
  const [salaryPeriod, setSalaryPeriod] = useState(defaultInput.salary_period);
  const [result, setResult] = useState(initialResult);
  const [status, setStatus] = useState("ready");
  const [errors, setErrors] = useState([]);

  const profileOptions = useMemo(
    () =>
      Object.entries(profileLabels)
        .filter(([category]) => liveRegimes.some((regime) => regime.category === category))
        .map(([value, label]) => ({ value, label })),
    [liveRegimes]
  );

  const regionOptions = useMemo(() => {
    const seenRegions = new Set();

    return liveRegimes.filter((regime) => {
      if (regime.category !== selectedCategory) return false;
      if (seenRegions.has(regime.region)) return false;

      seenRegions.add(regime.region);
      return true;
    });
  }, [liveRegimes, selectedCategory]);

  useEffect(() => {
    if (regionOptions.some((region) => region.region === selectedRegion)) return;

    setSelectedRegion(regionOptions[0]?.region || "");
  }, [regionOptions, selectedRegion]);

  const selectedRegime =
    liveRegimes.find(
      (regime) =>
        regime.category === selectedCategory && regime.region === selectedRegion
    ) || defaultRegime;

  const incomeLabel =
    selectedCategory === "self_employed" ? "Revenue before expenses" : "Gross income";
  const periodLabel =
    selectedCategory === "self_employed" ? "Income period" : "Salary period";
  const showDeductibleExpenses = selectedCategory === "self_employed";

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

  function resetFormState() {
    setErrors([]);
    setStatus("ready");
  }

  function handleCategoryChange(category) {
    setSelectedCategory(category);
    resetFormState();
  }

  function handleRegionChange(event) {
    setSelectedRegion(event.target.value);
    resetFormState();
  }

  async function handleSubmit(event) {
    event.preventDefault();
    if (!selectedRegime) return;

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
            deductible_expenses: showDeductibleExpenses ? deductibleExpenses : 0,
            salary_period: salaryPeriod,
            tax_regime_key: selectedRegime.key
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
            <div className="field-row">
              <div className="field">
                <span className="field-label">Tax profile</span>
                <div className="segmented-control">
                  {profileOptions.map((profile) => (
                    <button
                      key={profile.value}
                      className={profile.value === selectedCategory ? "is-active" : ""}
                      type="button"
                      onClick={() => handleCategoryChange(profile.value)}
                    >
                      {profile.label}
                    </button>
                  ))}
                </div>
              </div>

              <label className="field">
                <span className="field-label">Region</span>
                <div className="select-shell">
                  <select value={selectedRegion} onChange={handleRegionChange}>
                    {regionOptions.map((region) => (
                      <option key={region.key} value={region.region}>
                        {region.region}
                      </option>
                    ))}
                  </select>
                </div>
              </label>
            </div>

            <label className="field">
              <span className="field-label">{incomeLabel}</span>
              <div className="currency-input">
                <span>€</span>
                <input
                  type="number"
                  min="0"
                  step="0.01"
                  inputMode="decimal"
                  value={grossIncome}
                  onChange={(event) => {
                    setGrossIncome(event.target.value);
                    resetFormState();
                  }}
                />
              </div>
            </label>

            {showDeductibleExpenses ? (
              <label className="field">
                <span className="field-label">Deductible expenses</span>
                <div className="currency-input">
                  <span>€</span>
                  <input
                    type="number"
                    min="0"
                    step="0.01"
                    inputMode="decimal"
                    value={deductibleExpenses}
                    onChange={(event) => {
                      setDeductibleExpenses(event.target.value);
                      resetFormState();
                    }}
                  />
                </div>
              </label>
            ) : null}

            <div className="field">
              <span className="field-label">{periodLabel}</span>
              <div className="segmented-control">
                {["YEAR", "MONTH"].map((period) => (
                  <button
                    key={period}
                    className={period === salaryPeriod ? "is-active" : ""}
                    type="button"
                    onClick={() => {
                      setSalaryPeriod(period);
                      resetFormState();
                    }}
                  >
                    {period === "YEAR" ? "Annual" : "Monthly"}
                  </button>
                ))}
              </div>
            </div>

            <button className="primary-action" type="submit" disabled={status === "loading"}>
              {status === "loading" ? "Calculating..." : "Recalculate"}
            </button>
          </form>

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
            <span className={`response-state response-state--${status}`}>
              {result.metadata.tax_regime_name}
            </span>
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

          <div className="detail-grid">
            {result.detail_cards.map((card) => (
              <MetricCard
                key={card.label}
                label={card.label}
                value={formatCurrency(card.value)}
              />
            ))}
          </div>
        </section>

        <section className="liquid-card assumptions-card">
          <div className="section-head">
            <div>
              <p className="section-kicker">Traceability</p>
              <h2>Assumptions and source anchors</h2>
            </div>
          </div>

          <div className="assumption-list">
            {result.assumptions.map((assumption) => (
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
