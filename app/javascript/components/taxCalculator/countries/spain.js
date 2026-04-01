const spainCalculatorConfig = {
  calculationEndpoint: "/api/v1/spain/salary_calculation",
  fallbackTitle: "Spain tax estimate",
  sectionKicker: "EU tax calculator",
  formConfig: {
    showAgeField: true,
    ageFieldHint: null,
    showChildrenFields: true,
    showDisabilityField: true,
    ageBracketOptions: [
      { value: "under_65", label: "Under 65" },
      { value: "from_65_to_74", label: "65 to 74" },
      { value: "age_75_plus", label: "75+" }
    ]
  }
};

export default spainCalculatorConfig;
