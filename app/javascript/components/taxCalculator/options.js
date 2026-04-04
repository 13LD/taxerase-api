export const profileLabels = {
  employee: "Contract of employment",
  self_employed: "B2B contract"
};

export const ageBracketOptions = [
  { value: "under_65", label: "Under 65" },
  { value: "from_65_to_74", label: "65 to 74" },
  { value: "age_75_plus", label: "75+" }
];

export const defaultDisabilityLevelOptions = [
  { value: "none", label: "None" },
  { value: "level_33_to_64", label: "33% to 64%" },
  { value: "level_33_to_64_with_support", label: "33% to 64% + support" },
  { value: "level_65_plus", label: "65% or more" }
];

export const salaryPeriodOptions = [
  { value: "YEAR", label: "Annual" },
  { value: "MONTH", label: "Monthly" }
];

export function buildProfileOptions(regimesForYear, customProfileLabels = {}) {
  return Object.entries({ ...profileLabels, ...customProfileLabels })
    .filter(([category]) => regimesForYear.some((regime) => regime.category === category))
    .map(([value, label]) => ({ value, label }));
}

export function buildCountOptions(maxValue) {
  return Array.from({ length: maxValue + 1 }, (_item, index) => ({
    value: String(index),
    label: String(index)
  }));
}
