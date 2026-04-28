import { buildRegionOptions, findSelectedRegime } from "./selection";

export function buildComparisonCountryOptions(comparisonCatalog, selectedCategory) {
  return comparisonCatalog.filter((entry) =>
    entry.regime_options.some((regime) => regime.category === selectedCategory)
  );
}

export function findComparisonCountryEntry(comparisonCatalog, countryCode) {
  return comparisonCatalog.find((entry) => entry.country.code === countryCode) || null;
}

function buildComparisonTaxYearsForCountry(countryEntry, selectedCategory) {
  return Array.from(
    new Set(
      (countryEntry?.regime_options || [])
        .filter((regime) => regime.category === selectedCategory)
        .map((regime) => regime.tax_year)
    )
  ).sort((leftYear, rightYear) => leftYear - rightYear);
}

export function resolveComparisonTaxYear({
  leftCountryEntry,
  rightCountryEntry,
  selectedCategory
}) {
  const leftTaxYears = buildComparisonTaxYearsForCountry(leftCountryEntry, selectedCategory);
  const rightTaxYears = buildComparisonTaxYearsForCountry(rightCountryEntry, selectedCategory);
  const sharedTaxYears = leftTaxYears.filter((taxYear) => rightTaxYears.includes(taxYear));

  return sharedTaxYears[sharedTaxYears.length - 1] || null;
}

export function buildComparisonRegimesForCountry(countryEntry, selectedTaxYear, selectedCategory) {
  return (countryEntry?.regime_options || []).filter(
    (regime) => regime.tax_year === selectedTaxYear && regime.category === selectedCategory
  );
}

export function buildComparisonInputCurrencyOptions(leftCountryEntry, rightCountryEntry) {
  const seenCodes = new Set();

  return [
    ...(leftCountryEntry?.input_currency_options || []),
    ...(rightCountryEntry?.input_currency_options || [])
  ].filter((option) => {
    if (seenCodes.has(option.code)) return false;

    seenCodes.add(option.code);
    return true;
  });
}

export function resolveComparisonCountryCode({
  availableCountryOptions,
  preferredCountryCode,
  fallbackCountryCode
}) {
  if (availableCountryOptions.some((country) => country.country.code === preferredCountryCode)) {
    return preferredCountryCode;
  }

  if (availableCountryOptions.some((country) => country.country.code === fallbackCountryCode)) {
    return fallbackCountryCode;
  }

  return availableCountryOptions[0]?.country.code || "";
}

export function resolveComparisonRegionSelection({
  comparisonRegimes,
  preferredRegion,
  fallbackRegion
}) {
  const regionOptions = buildRegionOptions(comparisonRegimes, comparisonRegimes[0]?.category);
  const selectedRegion = regionOptions.some((region) => region.region === preferredRegion)
    ? preferredRegion
    : (regionOptions.some((region) => region.region === fallbackRegion)
        ? fallbackRegion
        : (regionOptions[0]?.region || ""));
  const selectedRegime = findSelectedRegime(
    comparisonRegimes,
    comparisonRegimes[0]?.category,
    selectedRegion
  );

  return {
    regionOptions,
    selectedRegion,
    selectedRegime
  };
}
