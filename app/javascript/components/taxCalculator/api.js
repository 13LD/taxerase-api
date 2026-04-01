function csrfToken() {
  return document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
}

export function buildCalculationPayload({
  grossIncome,
  deductibleExpenses,
  salaryPeriod,
  selectedTaxYear,
  selectedRegimeKey,
  ageBracket,
  childrenCount,
  childrenUnderThreeCount,
  disabilityLevel
}) {
  return {
    calculation: {
      gross_income: grossIncome,
      deductible_expenses: deductibleExpenses,
      salary_period: salaryPeriod,
      tax_year: selectedTaxYear,
      tax_regime_key: selectedRegimeKey,
      age_bracket: ageBracket,
      children_count: childrenCount,
      children_under_three_count: childrenUnderThreeCount,
      disability_level: disabilityLevel
    }
  };
}

export function buildComparisonPayload({
  deductibleExpenses,
  grossIncome,
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
