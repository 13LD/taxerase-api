import { formatCurrency } from "./formatters";
import { profileLabels } from "./options";

const COMPARISON_PROFILE_CONFIG = {
  employee: {
    comparisonContextLabel: "employed",
    countryDefaultsNote: null,
    deductibleExpensesLabel: null,
    graphicTitle: "Gross income vs tax load",
    incomeLabel: "Annual income",
    showDeductibleExpenses: false
  },
  self_employed: {
    comparisonContextLabel: "self-employed",
    countryDefaultsNote: "Country-specific default deduction methods may override the shared expense input for some jurisdictions.",
    deductibleExpensesLabel: "Annual deductible expenses",
    graphicTitle: "Revenue vs tax load",
    incomeLabel: "Annual revenue before expenses",
    showDeductibleExpenses: true
  }
};

export function buildComparisonProfileOptions(comparisonCatalog) {
  return Object.entries(profileLabels)
    .filter(([category]) => COMPARISON_PROFILE_CONFIG[category])
    .filter(([category]) =>
      comparisonCatalog.some((entry) =>
        entry.regime_options.some((regime) => regime.category === category)
      )
    )
    .map(([value, label]) => ({ value, label }));
}

export function resolveComparisonProfile(selectedCategoryPreference, profileOptions) {
  const selectedCategory = profileOptions.some(
    (profile) => profile.value === selectedCategoryPreference
  )
    ? selectedCategoryPreference
    : (profileOptions[0]?.value || "employee");

  return {
    key: selectedCategory,
    ...COMPARISON_PROFILE_CONFIG[selectedCategory]
  };
}

export function buildComparisonGraphicCopy({
  inputCurrencyCode,
  deductibleExpenses,
  grossIncome,
  incomeLabel,
  profile
}) {
  const normalizedIncomeLabel = incomeLabel.charAt(0).toLowerCase() + incomeLabel.slice(1);
  const incomeValue = formatCurrency(grossIncome, inputCurrencyCode);
  const expensesValue = formatCurrency(deductibleExpenses, inputCurrencyCode);

  if (!profile.showDeductibleExpenses) {
    return {
      introTitle: profile.graphicTitle,
      introSummary: `Based on ${normalizedIncomeLabel} ${incomeValue}.`,
      panelSummary: `${incomeLabel} ${incomeValue}`
    };
  }

  return {
    introTitle: profile.graphicTitle,
    introSummary:
      `Based on ${normalizedIncomeLabel} ${incomeValue} and ${profile.deductibleExpensesLabel.toLowerCase()} ` +
      `${expensesValue}.`,
    panelSummary:
      `Revenue ${incomeValue} · deductible expenses ${expensesValue}`
  };
}
