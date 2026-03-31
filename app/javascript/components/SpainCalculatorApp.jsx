import React, {
  startTransition,
  useEffect,
  useEffectEvent,
  useMemo,
  useRef,
  useState
} from "react";

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

function pendingOutputValue(selectedRegime, isSupportedRegime) {
  if (!selectedRegime) return "Not available";
  return isSupportedRegime ? "Calculating..." : "Research pending";
}

function placeholderDetailCards({
  selectedCategory,
  selectedRegion,
  pendingValue,
  deductibleExpenses
}) {
  if (selectedCategory === "self_employed") {
    return [
      { label: "Deductible expenses", value: formatCurrency(deductibleExpenses) },
      { label: "Net income before social security", value: pendingValue },
      { label: "Self-employed social security", value: pendingValue },
      { label: "5% difficult-to-justify deduction", value: pendingValue },
      { label: "Taxable activity income", value: pendingValue },
      { label: "Income tax", value: pendingValue },
      { label: "Total tax", value: pendingValue },
      { label: "Estimated monthly RETA base", value: pendingValue }
    ];
  }

  return [
    { label: "Income tax", value: pendingValue },
    { label: "Employee social security", value: pendingValue },
    { label: "Total tax", value: pendingValue },
    { label: "Taxable work income", value: pendingValue },
    { label: "State minimum relief", value: pendingValue },
    {
      label: `${selectedRegion || "Regional"} minimum relief`,
      value: pendingValue
    }
  ];
}

export default function SpainCalculatorApp({
  country,
  tax_year_options: taxYearOptions,
  default_tax_regime_key: defaultTaxRegimeKey,
  regime_options: regimeOptions,
  default_input: defaultInput,
  initial_result: initialResult,
  research_tracks: researchTracks
}) {
  const initialRegime =
    regimeOptions.find(
      (regime) =>
        regime.key === defaultTaxRegimeKey && regime.tax_year === defaultInput.tax_year
    ) || regimeOptions[0];

  const [selectedTaxYear, setSelectedTaxYear] = useState(defaultInput.tax_year);
  const [selectedCategory, setSelectedCategory] = useState(initialRegime?.category || "employee");
  const [selectedRegion, setSelectedRegion] = useState(initialRegime?.region || "");
  const [grossIncome, setGrossIncome] = useState(String(defaultInput.gross_income));
  const [deductibleExpenses, setDeductibleExpenses] = useState(
    String(defaultInput.deductible_expenses || 0)
  );
  const [salaryPeriod, setSalaryPeriod] = useState(defaultInput.salary_period);
  const [result, setResult] = useState(initialResult);
  const [status, setStatus] = useState("ready");
  const [errors, setErrors] = useState([]);
  const requestAbortControllerRef = useRef(null);

  const regimesForYear = useMemo(
    () => regimeOptions.filter((regime) => regime.tax_year === selectedTaxYear),
    [regimeOptions, selectedTaxYear]
  );

  const profileOptions = useMemo(
    () =>
      Object.entries(profileLabels)
        .filter(([category]) =>
          regimesForYear.some((regime) => regime.category === category)
        )
        .map(([value, label]) => ({ value, label })),
    [regimesForYear]
  );

  useEffect(() => {
    if (profileOptions.some((profile) => profile.value === selectedCategory)) return;

    setSelectedCategory(profileOptions[0]?.value || "employee");
  }, [profileOptions, selectedCategory]);

  const regionOptions = useMemo(() => {
    const seenRegions = new Set();

    return regimesForYear.filter((regime) => {
      if (regime.category !== selectedCategory) return false;
      if (seenRegions.has(regime.region)) return false;

      seenRegions.add(regime.region);
      return true;
    });
  }, [regimesForYear, selectedCategory]);

  useEffect(() => {
    if (regionOptions.some((region) => region.region === selectedRegion)) return;

    setSelectedRegion(regionOptions[0]?.region || "");
  }, [regionOptions, selectedRegion]);

  const selectedRegime =
    regimesForYear.find(
      (regime) =>
        regime.category === selectedCategory && regime.region === selectedRegion
    ) || null;
  const selectedRegimeKey = selectedRegime?.key || null;
  const selectedCalculationSignature = selectedRegimeKey
    ? `${selectedTaxYear}:${selectedRegimeKey}`
    : null;
  const resultCalculationSignature =
    result?.metadata?.tax_regime_key && result?.metadata?.tax_year
      ? `${result.metadata.tax_year}:${result.metadata.tax_regime_key}`
      : null;

  const isSupportedRegime = Boolean(selectedRegime?.supported);
  const resultMatchesSelection =
    selectedCalculationSignature !== null &&
    selectedCalculationSignature === resultCalculationSignature;
  const displayStatus = !selectedRegime
    ? "unavailable"
    : !isSupportedRegime
      ? "unavailable"
      : status === "error"
        ? "error"
      : resultMatchesSelection
        ? status
        : "loading";
  const incomeLabel =
    selectedCategory === "self_employed" ? "Revenue before expenses" : "Gross income";
  const periodLabel =
    selectedCategory === "self_employed" ? "Income period" : "Salary period";
  const showDeductibleExpenses = selectedCategory === "self_employed";
  const isCalculating = status === "loading" && Boolean(selectedRegime) && isSupportedRegime;
  const displayedSources = resultMatchesSelection
    ? result.sources
    : selectedRegime?.sources || [];
  const assumptionItems = resultMatchesSelection
    ? result.assumptions
    : selectedRegime
      ? [
          selectedRegime.description,
          isSupportedRegime
            ? "Refreshing the calculation for the selected year and jurisdiction."
            : "Official sources are mapped to this year and jurisdiction, but the calculator formula is still pending."
        ]
      : ["No regimes are seeded for this year yet."];
  const pendingValue = pendingOutputValue(selectedRegime, isSupportedRegime);

  const headlineMetrics = useMemo(
    () =>
      resultMatchesSelection
        ? [
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
          ]
        : [
            {
              label: "Annual net income",
              value: pendingValue,
              tone: "primary"
            },
            {
              label: "Monthly net income",
              value: pendingValue,
              tone: "secondary"
            },
            {
              label: "Effective tax rate",
              value: pendingValue,
              tone: "default"
            }
          ],
    [pendingValue, result, resultMatchesSelection]
  );
  const detailCards = resultMatchesSelection
    ? result.detail_cards.map((card) => ({
        label: card.label,
        value: formatCurrency(card.value)
      }))
    : placeholderDetailCards({
        selectedCategory,
        selectedRegion,
        pendingValue,
        deductibleExpenses: Number(deductibleExpenses || 0)
      });

  function resetFormState() {
    setErrors([]);
    setStatus("ready");
  }

  function prepareAutoRefresh() {
    setErrors([]);
    setStatus("loading");
  }

  function handleTaxYearChange(event) {
    setSelectedTaxYear(Number(event.target.value));
    prepareAutoRefresh();
  }

  function handleCategoryChange(category) {
    setSelectedCategory(category);
    prepareAutoRefresh();
  }

  function handleRegionChange(event) {
    setSelectedRegion(event.target.value);
    prepareAutoRefresh();
  }

  const submitCalculation = useEffectEvent(async () => {
    if (!selectedRegime || !isSupportedRegime) return;

    requestAbortControllerRef.current?.abort();

    const abortController = new AbortController();
    requestAbortControllerRef.current = abortController;

    setStatus("loading");
    setErrors([]);

    try {
      const response = await fetch("/api/v1/spain/salary_calculation", {
        method: "POST",
        signal: abortController.signal,
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
            tax_year: selectedTaxYear,
            tax_regime_key: selectedRegime.key
          }
        })
      });

      const payload = await response.json();
      if (abortController.signal.aborted) return;

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
      if (abortController.signal.aborted) return;

      setErrors(["Network error while calculating."]);
      setStatus("error");
    }
  });

  useEffect(() => {
    if (!selectedRegime || !isSupportedRegime) {
      requestAbortControllerRef.current?.abort();
      setStatus((currentStatus) =>
        currentStatus === "loading" ? "ready" : currentStatus
      );
      return;
    }

    if (selectedCalculationSignature === resultCalculationSignature) {
      setStatus((currentStatus) =>
        currentStatus === "loading" ? "ready" : currentStatus
      );
      return;
    }

    submitCalculation();
  }, [isSupportedRegime, resultCalculationSignature, selectedCalculationSignature]);

  useEffect(
    () => () => {
      requestAbortControllerRef.current?.abort();
    },
    []
  );

  async function handleSubmit(event) {
    event.preventDefault();

    await submitCalculation();
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
              {country.name} · {selectedTaxYear}
            </span>
          </div>

          <form className="calculator-form" onSubmit={handleSubmit}>
            <div className="field-row">
              <label className="field">
                <span className="field-label">Tax year</span>
                <div className="select-shell">
                  <select value={selectedTaxYear} onChange={handleTaxYearChange}>
                    {taxYearOptions.map((year) => (
                      <option key={year} value={year}>
                        {year}
                      </option>
                    ))}
                  </select>
                </div>
              </label>

              <label className="field">
                <span className="field-label">Region</span>
                <div className="select-shell">
                  <select value={selectedRegion} onChange={handleRegionChange}>
                    {regionOptions.map((region) => (
                      <option key={`${region.tax_year}-${region.key}`} value={region.region}>
                        {region.region}
                      </option>
                    ))}
                  </select>
                </div>
              </label>
            </div>

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

            <button
              className="primary-action"
              type="submit"
              disabled={isCalculating || !selectedRegime || !isSupportedRegime}
            >
              {isCalculating ? "Calculating..." : "Recalculate"}
            </button>
          </form>

          {!selectedRegime ? (
            <div className="availability-note">
              <p>No regimes are seeded for {selectedTaxYear} yet.</p>
            </div>
          ) : null}

          {selectedRegime && !isSupportedRegime ? (
            <div className="availability-note">
              <p>{selectedRegime.status} only: official sources are linked for this year and jurisdiction, but the calculator flow is still pending.</p>
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
      </div>

      <div className="glass-stack">
        <section className="liquid-card results-card">
          <div className="section-head">
            <div>
              <p className="section-kicker">Output</p>
              <h2>Transparent tax breakdown</h2>
            </div>
            <span className={`response-state response-state--${displayStatus}`}>
              {selectedRegime?.name || `${selectedTaxYear} pending`}
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
            {detailCards.map((card) => (
              <MetricCard key={card.label} label={card.label} value={card.value} />
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
      </div>

      <section className="liquid-card tracks-card tracks-card--full">
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
    </section>
  );
}
