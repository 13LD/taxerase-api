function csrfToken() {
  return document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
}

function normalizeBlankNumericValue(value) {
  if (value === null || value === undefined) return 0;
  if (String(value).trim() === "") return 0;

  return value;
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
      gross_income: normalizeBlankNumericValue(grossIncome),
      input_currency_code: inputCurrencyCode,
      deductible_expenses: normalizeBlankNumericValue(deductibleExpenses),
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
      deductible_expenses: normalizeBlankNumericValue(deductibleExpenses),
      gross_income: normalizeBlankNumericValue(grossIncome),
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

export async function requestCountryCalculator({ countryCode, profileType, signal }) {
  const url = new URL(`/api/v1/countries/${encodeURIComponent(countryCode)}/calculator`, window.location.origin);
  if (profileType) url.searchParams.set("profile_type", profileType);

  return fetch(url.toString(), {
    method: "GET",
    signal,
    headers: {
      Accept: "application/json",
      "X-CSRF-Token": csrfToken()
    }
  });
}

export async function requestReportCalendar({ countryCode, profileType, signal, taxYear }) {
  const url = new URL(`/api/v1/countries/${encodeURIComponent(countryCode)}/report_calendar`, window.location.origin);
  if (profileType) url.searchParams.set("profile_type", profileType);
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
