const netherlandsCalculatorConfig = {
  calculationEndpoint: "/api/v1/netherlands/salary_calculation",
  fallbackTitle: "Netherlands tax estimate",
  sectionKicker: "EU tax calculator",
  formConfig: {
    showAgeField: true,
    ageFieldHint: "For the supported Netherlands tax years 2024 and 2025, AOW age is 67.",
    showChildrenFields: false,
    showDisabilityField: false,
    ageBracketOptions: [
      { value: "under_aow_age", label: "Below AOW age (under 67)" },
      { value: "aow_age_or_older", label: "AOW age or older (67+)" }
    ]
  }
};

export default netherlandsCalculatorConfig;
