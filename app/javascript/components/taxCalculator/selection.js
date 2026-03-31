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

export function buildCalculationSignature({
  selectedTaxYear,
  selectedRegimeKey,
  ageBracket,
  childrenCount,
  childrenUnderThreeCount,
  disabilityLevel
}) {
  if (!selectedRegimeKey) return null;

  return [
    selectedTaxYear,
    selectedRegimeKey,
    ageBracket,
    childrenCount,
    childrenUnderThreeCount,
    disabilityLevel
  ].join(":");
}

export function buildResultCalculationSignature(result) {
  if (
    !result?.metadata?.tax_regime_key ||
    !result?.metadata?.tax_year ||
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
    result.input.age_bracket,
    result.input.children_count,
    result.input.children_under_three_count,
    result.input.disability_level
  ].join(":");
}
