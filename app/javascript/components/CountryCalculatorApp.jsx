import React, { startTransition, useCallback, useEffect, useRef, useState } from "react";
import CalculatorHomeTab from "./CalculatorHomeTab";
import ComparisonTab from "./ComparisonTab";
import ReportCalendarPanel from "./ReportCalendarPanel";
import { requestCountryCalculator } from "./taxCalculator/api";

const TAB_OPTIONS = [
  {
    key: "calculator",
    label: "Calculator",
    iconLabel: "C"
  },
  {
    key: "comparison",
    label: "Comparison",
    iconLabel: "Co"
  },
  {
    key: "calendar",
    label: "Calendar",
    iconLabel: "Ca"
  },
  {
    key: "invoice",
    label: "Invoices",
    iconLabel: "In"
  },
  {
    key: "expenses",
    label: "Expenses",
    iconLabel: "Ex"
  },
  {
    key: "reports",
    label: "Reports",
    iconLabel: "R"
  }
];

const LEGACY_TAB_ALIASES = {
  invoice_expenses: "invoice"
};

const PROFILE_CATEGORY_PARAMS = {
  employee: "employee",
  self_employed: "self_employed"
};

const PLACEHOLDER_PANELS = [
  {
    key: "invoice",
    kicker: "Invoices",
    title: "Invoices",
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

function currentReturnPath() {
  if (typeof window === "undefined") return "/";

  return `${window.location.pathname}${window.location.search}`;
}

function authPathWithReturnTo(path) {
  if (typeof window === "undefined") return path;

  const url = new URL(path || "/sign_in", window.location.origin);
  url.searchParams.set("return_to", currentReturnPath());

  return `${url.pathname}${url.search}`;
}

function currentProfileTypeParam() {
  if (typeof window === "undefined") return null;

  const currentUrl = new URL(window.location.href);
  return currentUrl.searchParams.get("profile_type");
}

function profileTypeParamForCategory(category) {
  return PROFILE_CATEGORY_PARAMS[category] || null;
}

export default function CountryCalculatorApp(initialProps = {}) {
  const [calculatorProps, setCalculatorProps] = useState(initialProps);
  const [activeTab, setActiveTab] = useState(() => activeTabFromLocation());
  const [countrySwitchErrors, setCountrySwitchErrors] = useState([]);
  const [isCountrySwitching, setIsCountrySwitching] = useState(false);
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const requestAbortControllerRef = useRef(null);
  const activeTabRef = useRef(activeTab);
  const auth = calculatorProps.auth || {};

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
          profileType: currentProfileTypeParam() || auth.profile_type,
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
    [auth.profile_type, calculatorProps.country?.code, updateUrl]
  );

  const handleProfileTypeChangeRequest = useCallback((category) => {
    const profileType = profileTypeParamForCategory(category);
    if (!profileType) return;

    updateUrl((searchParams) => {
      searchParams.set("profile_type", profileType);
      searchParams.set("tab", activeTabRef.current);
    });
  }, [updateUrl]);

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
            </button>
          ))}
        </div>

        <div className="workspace-sidebar__account" aria-label="User profile">
          {auth.signed_in ? (
            <a
              className="workspace-sidebar__profile"
              href={authPathWithReturnTo(auth.profile_path || "/profile/edit")}
            >
              <span className="workspace-sidebar__avatar" aria-hidden="true">
                {(auth.email || "U").charAt(0).toUpperCase()}
              </span>
              <div>
                <strong>Edit profile</strong>
                <span title={auth.email || undefined}>
                  {auth.selected_country_name || auth.email || "Account space"}
                </span>
              </div>
            </a>
          ) : (
            <div className="workspace-sidebar__profile">
              <span className="workspace-sidebar__avatar" aria-hidden="true">U</span>
              <div>
                <strong>Guest</strong>
                <span>Limited workspace</span>
              </div>
            </div>
          )}
          <div className="workspace-sidebar__account-actions">
            {auth.signed_in ? (
              <form action={auth.sign_out_path || "/sign_out"} method="post">
                <input name="_method" type="hidden" value="delete" />
                <input
                  name="authenticity_token"
                  type="hidden"
                  value={auth.authenticity_token || ""}
                />
                <button className="secondary-action" type="submit">Sign out</button>
              </form>
            ) : (
              <a className="primary-action" href={authPathWithReturnTo(auth.sign_in_path)}>
                Sign in
              </a>
            )}
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
            onProfileTypeChangeRequest={handleProfileTypeChangeRequest}
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

        <div
          aria-hidden={activeTab !== "calendar"}
          className="tabbed-calculator-shell__panel"
          hidden={activeTab !== "calendar"}
          id="calendar-panel"
          role="tabpanel"
        >
          <ReportCalendarPanel
            active={activeTab === "calendar"}
            countryCode={calculatorProps.country?.code}
            profileType={currentProfileTypeParam() || auth.profile_type}
          />
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
