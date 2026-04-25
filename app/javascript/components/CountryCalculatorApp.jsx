import React, { startTransition, useCallback, useEffect, useRef, useState } from "react";
import CalculatorHomeTab from "./CalculatorHomeTab";
import ComparisonTab from "./ComparisonTab";
import { requestCountryCalculator } from "./taxCalculator/api";

const TAB_OPTIONS = [
  {
    key: "calculator",
    label: "Calculator",
    description: "Country tax estimate.",
    iconLabel: "C"
  },
  {
    key: "comparison",
    label: "Comparison",
    description: "Two-country workspace.",
    iconLabel: "Co"
  },
  {
    key: "calendar",
    label: "Calendar",
    description: "Filing dates workspace.",
    iconLabel: "Ca"
  },
  {
    key: "invoice",
    label: "Invoice",
    description: "Billing workspace.",
    iconLabel: "In"
  },
  {
    key: "expenses",
    label: "Expenses",
    description: "Expense tracking lane.",
    iconLabel: "Ex"
  },
  {
    key: "reports",
    label: "Reports",
    description: "Tax report workspace.",
    iconLabel: "R"
  }
];

const LEGACY_TAB_ALIASES = {
  invoice_expenses: "invoice"
};

const PLACEHOLDER_PANELS = [
  {
    key: "calendar",
    kicker: "Tax calendar",
    title: "Calendar",
    body: "Filing date tracking will live here."
  },
  {
    key: "invoice",
    kicker: "Invoice",
    title: "Invoice",
    body: "Invoice workflows will live here."
  },
  {
    key: "expenses",
    kicker: "Expenses",
    title: "Expenses",
    body: "Expense workflows will live here."
  },
  {
    key: "reports",
    kicker: "Reports",
    title: "Reports",
    body: "Tax report workflows will live here."
  }
];

function normalizeTab(tab) {
  const normalizedTab = LEGACY_TAB_ALIASES[tab] || tab;

  return TAB_OPTIONS.some((option) => option.key === normalizedTab) ? normalizedTab : "calculator";
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
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
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
    setIsSidebarOpen(false);
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
      <aside
        className={`workspace-sidebar${isSidebarOpen ? " is-open" : ""}`}
        aria-label="Taxerase workspace navigation"
      >
        <div className="workspace-sidebar__brand">
          <div className="workspace-sidebar__brand-lockup">
            <span className="workspace-sidebar__brand-mark" aria-hidden="true">T</span>
            <span>Taxerase</span>
          </div>
          <button
            aria-controls="workspace-sidebar-menu"
            aria-expanded={isSidebarOpen}
            aria-label="Toggle workspace navigation"
            className="workspace-sidebar__toggle"
            onClick={() => setIsSidebarOpen((currentValue) => !currentValue)}
            type="button"
          >
            <span aria-hidden="true" />
            <span aria-hidden="true" />
            <span aria-hidden="true" />
          </button>
        </div>

        <div
          aria-label="Tax workspace tabs"
          className="calculator-tabs"
          id="workspace-sidebar-menu"
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
              <span className="calculator-tabs__icon" aria-hidden="true">{tab.iconLabel}</span>
              <span>{tab.label}</span>
              <small>{tab.description}</small>
            </button>
          ))}
        </div>

        <div className="workspace-sidebar__profile" aria-label="User profile">
          <span className="workspace-sidebar__avatar" aria-hidden="true">U</span>
          <div>
            <strong>User profile</strong>
            <span>Account space</span>
          </div>
        </div>
      </aside>

      <main className="workspace-main">
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

        {PLACEHOLDER_PANELS.map((panel) => (
          <div
            aria-hidden={activeTab !== panel.key}
            className="tabbed-calculator-shell__panel"
            hidden={activeTab !== panel.key}
            id={`${panel.key}-panel`}
            key={panel.key}
            role="tabpanel"
          >
            <section className="liquid-card workspace-placeholder">
              <p className="section-kicker">{panel.kicker}</p>
              <h2>{panel.title}</h2>
              <p>{panel.body}</p>
            </section>
          </div>
        ))}
      </main>
    </section>
  );
}
