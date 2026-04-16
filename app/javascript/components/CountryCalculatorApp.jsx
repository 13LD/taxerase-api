import React, { startTransition, useCallback, useEffect, useRef, useState } from "react";
import CalculatorHomeTab from "./CalculatorHomeTab";
import ComparisonTab from "./ComparisonTab";
import { requestCountryCalculator } from "./taxCalculator/api";

const TAB_OPTIONS = [
  {
    key: "calculator",
    label: "Calculator",
    description: "Single-country calculator with detailed regime context."
  },
  {
    key: "comparison",
    label: "Compare 2 countries or regions",
    description: "Dedicated two-country comparison workspace."
  }
];

function normalizeTab(tab) {
  return tab === "comparison" ? "comparison" : "calculator";
}

function activeTabFromLocation() {
  if (typeof window === "undefined") return "calculator";

  const currentUrl = new URL(window.location.href);
  return normalizeTab(currentUrl.searchParams.get("tab"));
}

export default function CountryCalculatorApp(initialProps = {}) {
  const [calculatorProps, setCalculatorProps] = useState(initialProps);
  const [activeTab, setActiveTab] = useState(() => activeTabFromLocation());
  const [countrySwitchErrors, setCountrySwitchErrors] = useState([]);
  const [isCountrySwitching, setIsCountrySwitching] = useState(false);
  const requestAbortControllerRef = useRef(null);
  const activeTabRef = useRef(activeTab);

  useEffect(() => {
    activeTabRef.current = activeTab;
  }, [activeTab]);

  useEffect(() => {
    const handlePopState = () => {
      setActiveTab(activeTabFromLocation());
    };

    window.addEventListener("popstate", handlePopState);
    return () => window.removeEventListener("popstate", handlePopState);
  }, []);

  useEffect(
    () => () => {
      requestAbortControllerRef.current?.abort();
    },
    []
  );

  const updateUrl = useCallback((mutateSearchParams) => {
    const nextUrl = new URL(window.location.href);
    mutateSearchParams(nextUrl.searchParams);
    window.history.replaceState({}, "", nextUrl.toString());
  }, []);

  const handleTabChange = useCallback((nextTab) => {
    const normalizedTab = normalizeTab(nextTab);
    setActiveTab(normalizedTab);
    updateUrl((searchParams) => {
      searchParams.set("tab", normalizedTab);
    });
  }, [updateUrl]);

  const handleCountryChangeRequest = useCallback(
    async (nextCountryCode) => {
      if (!nextCountryCode || nextCountryCode === calculatorProps.country?.code) return;

      requestAbortControllerRef.current?.abort();

      const abortController = new AbortController();
      requestAbortControllerRef.current = abortController;
      setCountrySwitchErrors([]);
      setIsCountrySwitching(true);

      try {
        const response = await requestCountryCalculator({
          countryCode: nextCountryCode,
          signal: abortController.signal
        });
        const payload = await response.json();

        if (abortController.signal.aborted) return;

        if (!response.ok) {
          setCountrySwitchErrors(payload.errors || [ "The calculator could not switch countries." ]);
          setIsCountrySwitching(false);
          return;
        }

        startTransition(() => {
          setCalculatorProps(payload.calculator_props);
        });

        if (payload.page_title) document.title = payload.page_title;

        updateUrl((searchParams) => {
          searchParams.set("country", nextCountryCode);
          searchParams.set("tab", activeTabRef.current);
        });
        setIsCountrySwitching(false);
      } catch {
        if (abortController.signal.aborted) return;

        setCountrySwitchErrors([ "Network error while switching countries." ]);
        setIsCountrySwitching(false);
      }
    },
    [calculatorProps.country?.code, updateUrl]
  );

  return (
    <section className="tabbed-calculator-shell">
      <section className="liquid-card calculator-tabs-card">
        <div className="section-head">
          <div>
            <p className="section-kicker">Tax Workspace</p>
            <h2>Select a mode</h2>
          </div>
        </div>

        <div
          aria-label="Tax workspace tabs"
          className="calculator-tabs"
          role="tablist"
        >
          {TAB_OPTIONS.map((tab) => (
            <button
              aria-controls={`${tab.key}-panel`}
              aria-selected={activeTab === tab.key}
              className={`calculator-tabs__tab${activeTab === tab.key ? " is-active" : ""}`}
              id={`${tab.key}-tab`}
              key={tab.key}
              onClick={() => handleTabChange(tab.key)}
              role="tab"
              type="button"
            >
              <span>{tab.label}</span>
              <small>{tab.description}</small>
            </button>
          ))}
        </div>
      </section>

      <div
        aria-hidden={activeTab !== "calculator"}
        className="tabbed-calculator-shell__panel"
        hidden={activeTab !== "calculator"}
        id="calculator-panel"
        role="tabpanel"
      >
        <CalculatorHomeTab
          key={calculatorProps.country?.code || "calculator"}
          calculatorProps={calculatorProps}
          countrySwitchErrors={countrySwitchErrors}
          isCountrySwitching={isCountrySwitching}
          onCountryChangeRequest={handleCountryChangeRequest}
        />
      </div>

      <div
        aria-hidden={activeTab !== "comparison"}
        className="tabbed-calculator-shell__panel"
        hidden={activeTab !== "comparison"}
        id="comparison-panel"
        role="tabpanel"
      >
        <ComparisonTab calculatorProps={calculatorProps} enabled={activeTab === "comparison"} />
      </div>
    </section>
  );
}
