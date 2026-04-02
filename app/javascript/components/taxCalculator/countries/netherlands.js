const netherlandsCalculatorConfig = {
  calculationEndpoint: "/api/v1/netherlands/salary_calculation",
  fallbackTitle: "Netherlands tax estimate",
  sectionKicker: "EU tax calculator",
  formConfig: {
    regimeControls: [
      {
        key: "apply_thirty_percent_ruling",
        type: "checkbox",
        label: "Apply 30% ruling",
        hint:
          "2025 thresholds: €46,660 standard or €35,468 if you are under 30 with a master's degree. From January 2026: €48,013 / €36,497. Scientific research and doctor specialist training have no salary threshold.",
        categories: [ "employee" ],
        defaultValue: false,
        resultInputKey: "apply_thirty_percent_ruling",
        children: [
          {
            key: "thirty_percent_ruling_basis",
            type: "select",
            label: "30% ruling basis",
            categories: [ "employee" ],
            defaultValue: "standard_threshold",
            resultInputKey: "thirty_percent_ruling_basis",
            options: [
              { value: "standard_threshold", label: "Standard salary threshold" },
              { value: "under_30_masters", label: "Under 30 with master's degree" },
              {
                value: "scientific_research",
                label: "Scientific research or doctor specialist training"
              }
            ],
            visibleWhen: (controlValues) => Boolean(controlValues.apply_thirty_percent_ruling)
          }
        ]
      }
    ],
    showAgeField: true,
    ageFieldHint: "For the supported Netherlands tax years 2024 and 2025, AOW age is 67.",
    showChildrenCountField: false,
    showChildrenUnderThreeField: false,
    showDisabilityField: false,
    ageBracketOptions: [
      { value: "under_aow_age", label: "Below AOW age (under 67)" },
      { value: "aow_age_or_older", label: "AOW age or older (67+)" }
    ]
  }
};

export default netherlandsCalculatorConfig;
