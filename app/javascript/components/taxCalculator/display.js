import { formatCurrency, formatPercentage } from "./formatters";

export function pendingOutputValue(selectedRegime, isSupportedRegime) {
  if (!selectedRegime) return "Not available";
  return isSupportedRegime ? "Calculating..." : "Research pending";
}

export function buildPlaceholderDetailCards({
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
      { label: "State personal and family minimum", value: pendingValue },
      {
        label: `${selectedRegion || "Regional"} personal and family minimum`,
        value: pendingValue
      },
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
    { label: "State personal and family minimum", value: pendingValue },
    {
      label: `${selectedRegion || "Regional"} personal and family minimum`,
      value: pendingValue
    },
    { label: "State minimum relief", value: pendingValue },
    { label: `${selectedRegion || "Regional"} minimum relief`, value: pendingValue }
  ];
}

export function buildHeadlineMetrics({ pendingValue, result, resultMatchesSelection }) {
  if (resultMatchesSelection) {
    return [
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
    ];
  }

  return [
    { label: "Annual net income", value: pendingValue, tone: "primary" },
    { label: "Monthly net income", value: pendingValue, tone: "secondary" },
    { label: "Effective tax rate", value: pendingValue, tone: "default" }
  ];
}

export function buildDetailCards({
  result,
  resultMatchesSelection,
  selectedCategory,
  selectedRegion,
  pendingValue,
  deductibleExpenses
}) {
  if (resultMatchesSelection) {
    return result.detail_cards.map((card) => ({
      label: card.label,
      value: formatCurrency(card.value)
    }));
  }

  if (result?.detail_cards?.length) {
    return result.detail_cards.map((card) => ({
      label: card.label,
      value: card.label === "Deductible expenses" ? formatCurrency(deductibleExpenses) : pendingValue
    }));
  }

  return buildPlaceholderDetailCards({
    selectedCategory,
    selectedRegion,
    pendingValue,
    deductibleExpenses
  });
}

export function buildDisplayStatus({
  displayStatus,
  isSupportedRegime,
  resultMatchesSelection,
  selectedRegime,
  status
}) {
  if (!selectedRegime) return "unavailable";
  if (!isSupportedRegime) return "unavailable";
  if (status === "error") return "error";
  if (resultMatchesSelection) return status;
  return displayStatus || "loading";
}

export function buildDisplayedSources({ resultMatchesSelection, result, selectedRegime }) {
  return resultMatchesSelection ? result.sources : selectedRegime?.sources || [];
}

export function buildAssumptionItems({ isSupportedRegime, result, resultMatchesSelection, selectedRegime }) {
  if (resultMatchesSelection) return result.assumptions;
  if (!selectedRegime) return ["No regimes are seeded for this year yet."];

  return [
    selectedRegime.description,
    isSupportedRegime
      ? "Refreshing the calculation for the selected year and jurisdiction."
      : "Official sources are mapped to this year and jurisdiction, but the calculator formula is still pending."
  ];
}
