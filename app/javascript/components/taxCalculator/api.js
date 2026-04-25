function csrfToken() {
  return document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
}

export function buildCalculationPayload({
  grossIncome,
  inputCurrencyCode,
  deductibleExpenses,
  salaryPeriod,
  selectedTaxYear,
  selectedRegimeKey,
  ageBracket,
  childrenCount,
  childrenUnderThreeCount,
  disabilityLevel,
  regimeControlPayload
}) {
  return {
    calculation: {
      gross_income: grossIncome,
      input_currency_code: inputCurrencyCode,
      deductible_expenses: deductibleExpenses,
      salary_period: salaryPeriod,
      tax_year: selectedTaxYear,
      tax_regime_key: selectedRegimeKey,
      age_bracket: ageBracket,
      children_count: childrenCount,
      children_under_three_count: childrenUnderThreeCount,
      disability_level: disabilityLevel,
      ...regimeControlPayload
    }
  };
}

export function buildComparisonPayload({
  deductibleExpenses,
  grossIncome,
  inputCurrencyCode,
  leftCountryCode,
  leftTaxRegimeKey,
  rightCountryCode,
  rightTaxRegimeKey,
  selectedCategory,
  selectedTaxYear
}) {
  return {
    comparison: {
      deductible_expenses: deductibleExpenses,
      gross_income: grossIncome,
      input_currency_code: inputCurrencyCode,
      left_country_code: leftCountryCode,
      left_tax_regime_key: leftTaxRegimeKey,
      right_country_code: rightCountryCode,
      right_tax_regime_key: rightTaxRegimeKey,
      salary_period: "YEAR",
      selected_category: selectedCategory,
      tax_year: selectedTaxYear
    }
  };
}

export async function requestCalculation({ endpoint, payload, signal }) {
  return fetch(endpoint, {
    method: "POST",
    signal,
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-CSRF-Token": csrfToken()
    },
    body: JSON.stringify(payload)
  });
}

export async function requestComparison({ payload, signal }) {
  return fetch("/api/v1/comparisons", {
    method: "POST",
    signal,
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-CSRF-Token": csrfToken()
    },
    body: JSON.stringify(payload)
  });
}

export async function requestCountryCalculator({ countryCode, signal }) {
  return fetch(`/api/v1/countries/${encodeURIComponent(countryCode)}/calculator`, {
    method: "GET",
    signal,
    headers: {
      Accept: "application/json",
      "X-CSRF-Token": csrfToken()
    }
  });
}

export async function requestReportCalendar({ countryCode, signal, taxYear }) {
  const url = new URL(`/api/v1/countries/${encodeURIComponent(countryCode)}/report_calendar`, window.location.origin);
  if (taxYear) url.searchParams.set("tax_year", taxYear);

  return fetch(url.toString(), {
    method: "GET",
    signal,
    headers: {
      Accept: "application/json",
      "X-CSRF-Token": csrfToken()
    }
  });
}
