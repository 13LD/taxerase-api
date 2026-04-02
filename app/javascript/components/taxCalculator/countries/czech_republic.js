const czechRepublicCalculatorConfig = {
  calculationEndpoint: "/api/v1/czech_republic/salary_calculation",
  fallbackTitle: "Czech Republic tax estimate",
  sectionKicker: "EU tax calculator",
  formConfig: {
    regimeControls: [
      {
        key: "expense_deduction_method",
        type: "select",
        label: "Expense method",
        categories: ["self_employed"],
        resultInputKey: "expense_deduction_method",
        activeWhen: (value) => value === "flat_expense_60",
        effects: {
          hideDeductibleExpenses: true
        },
        hint: "The 60% flat expense method is common for standard trade income. The calculator caps flat expenses at CZK 1,200,000 a year.",
        options: [
          { value: "flat_expense_60", label: "60% flat expenses" },
          { value: "actual_expenses", label: "Actual deductible expenses" }
        ]
      }
    ],
    showAgeField: false,
    ageFieldHint: null,
    showChildrenCountField: true,
    showChildrenUnderThreeField: false,
    showDisabilityField: true,
    ageBracketOptions: [],
    disabilityOptions: [
      { value: "none", label: "None" },
      { value: "invalidity_first_or_second_degree", label: "Invalidity degree 1 or 2" },
      { value: "invalidity_third_degree", label: "Invalidity degree 3" },
      { value: "ztp_p", label: "ZTP/P card holder" }
    ]
  }
};

export default czechRepublicCalculatorConfig;
