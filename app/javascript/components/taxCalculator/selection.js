export function findInitialRegime({ regimeOptions, defaultTaxRegimeKey, defaultTaxYear }) {
  return (
    regimeOptions.find(
      (regime) => regime.key === defaultTaxRegimeKey && regime.tax_year === defaultTaxYear
    ) || regimeOptions[0]
  );
}

export function buildRegionOptions(regimesForYear, selectedCategory) {
  const seenRegions = new Set();

  return regimesForYear.filter((regime) => {
    if (regime.category !== selectedCategory) return false;
    if (seenRegions.has(regime.region)) return false;

    seenRegions.add(regime.region);
    return true;
  });
}

export function findSelectedRegime(regimesForYear, selectedCategory, selectedRegion) {
  return (
    regimesForYear.find(
      (regime) => regime.category === selectedCategory && regime.region === selectedRegion
    ) || null
  );
}

export function resolveSelectedRegime({
  regimesForYear,
  selectedCategory,
  selectedRegion,
  regimeCategoryOverride = null
}) {
  const effectiveCategory = regimeCategoryOverride || selectedCategory;

  return (
    findSelectedRegime(regimesForYear, effectiveCategory, selectedRegion) ||
    findSelectedRegime(regimesForYear, selectedCategory, selectedRegion)
  );
}

export function buildCalculationSignature({
  selectedTaxYear,
  selectedRegimeKey,
  grossIncome,
  salaryPeriod,
  ageBracket,
  childrenCount,
  childrenUnderThreeCount,
  disabilityLevel,
  extraSignatureParts = []
}) {
  if (!selectedRegimeKey) return null;

  return [
    selectedTaxYear,
    selectedRegimeKey,
    grossIncome,
    salaryPeriod,
    ageBracket,
    childrenCount,
    childrenUnderThreeCount,
    disabilityLevel,
    ...extraSignatureParts
  ].join(":");
}

function normalizeGrossIncomeForSignature(grossIncome) {
  if (grossIncome === null || grossIncome === undefined) return grossIncome;

  const rawValue = String(grossIncome).trim();
  if (rawValue === "") return grossIncome;

  const numericValue = Number(rawValue);
  return Number.isFinite(numericValue) ? numericValue : grossIncome;
}

export function buildSelectionResultSignature({
  selectedTaxYear,
  selectedRegimeKey,
  grossIncome,
  salaryPeriod,
  ageBracket,
  childrenCount,
  childrenUnderThreeCount,
  disabilityLevel,
  extraSignatureParts = []
}) {
  if (!selectedRegimeKey) return null;

  const normalizedGrossIncome = normalizeGrossIncomeForSignature(grossIncome);

  return [
    selectedTaxYear,
    selectedRegimeKey,
    normalizedGrossIncome,
    salaryPeriod,
    ageBracket,
    childrenCount,
    childrenUnderThreeCount,
    disabilityLevel,
    ...extraSignatureParts
  ].join(":");
}

export function buildResultCalculationSignature(result, extraSignatureParts = []) {
  if (
    !result?.metadata?.tax_regime_key ||
    !result?.metadata?.tax_year ||
    result?.input?.gross_income === undefined ||
    !result?.input?.salary_period ||
    !result?.input?.age_bracket ||
    result?.input?.children_count === undefined ||
    result?.input?.children_under_three_count === undefined ||
    !result?.input?.disability_level
  ) {
    return null;
  }

  return [
    result.metadata.tax_year,
    result.metadata.tax_regime_key,
    normalizeGrossIncomeForSignature(result.input.gross_income),
    result.input.salary_period,
    result.input.age_bracket,
    result.input.children_count,
    result.input.children_under_three_count,
    result.input.disability_level,
    ...extraSignatureParts
  ].join(":");
}
