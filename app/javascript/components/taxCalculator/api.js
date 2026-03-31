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
