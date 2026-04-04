const spainCalculatorConfig = {
  calculationEndpoint: "/api/v1/spain/salary_calculation",
  fallbackTitle: "Spain tax estimate",
  sectionKicker: "EU tax calculator",
  formConfig: {
    regimeControls: [
      {
        key: "apply_beckham_law",
        type: "checkbox",
        label: "Apply Beckham Law",
        hint:
          "Article 93 special regime for eligible inbound workers. Employment income is taxed at national special-regime rates instead of the ordinary regional IRPF scale, generally for the arrival year plus five more years.",
        categories: [ "employee" ],
        defaultValue: false,
        effects: {
          regimeCategoryOverride: "special_regime",
          incomeLabel: "Gross income",
          hidePersonalReliefFields: true
        }
      }
    ],
    showAgeField: true,
    ageFieldHint: null,
    showChildrenCountField: true,
    showChildrenUnderThreeField: true,
    showDisabilityField: true,
    ageBracketOptions: [
      { value: "under_65", label: "Under 65" },
      { value: "from_65_to_74", label: "65 to 74" },
      { value: "age_75_plus", label: "75+" }
    ]
  }
};

export default spainCalculatorConfig;
