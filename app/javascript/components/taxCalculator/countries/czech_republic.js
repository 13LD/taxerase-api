const standardTaxMode = (controlValues, selectedCategory) =>
  selectedCategory !== "self_employed" ||
  ![ "pausal_band_1", "pausal_band_2", "pausal_band_3" ].includes(controlValues.self_employed_tax_mode);

const spouseCreditDetailsVisible = (controlValues, selectedCategory) =>
  standardTaxMode(controlValues, selectedCategory) && Boolean(controlValues.apply_spouse_credit);

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
        activeWhen: (value) => value !== "actual_expenses",
        effects: {
          hideDeductibleExpenses: true
        },
        hint: "Flat expense methods use deemed costs by activity class and cap the annual expense amount. Actual expenses use the amount entered in deductible expenses.",
        options: [
          { value: "flat_expense_80", label: "80% flat expenses" },
          { value: "flat_expense_60", label: "60% flat expenses" },
          { value: "flat_expense_40", label: "40% flat expenses" },
          { value: "flat_expense_30", label: "30% flat expenses" },
          { value: "actual_expenses", label: "Actual deductible expenses" }
        ]
      },
      {
        key: "self_employed_tax_mode",
        type: "select",
        label: "Self-employed tax mode",
        categories: ["self_employed"],
        resultInputKey: "self_employed_tax_mode",
        hint: "Standard mode calculates tax, social security, and health insurance from profit. Pausalni dan bands use the fixed monthly combined payment for that band.",
        options: [
          { value: "standard", label: "Standard calculation" },
          { value: "pausal_band_1", label: "Pausalni dan band 1" },
          { value: "pausal_band_2", label: "Pausalni dan band 2" },
          { value: "pausal_band_3", label: "Pausalni dan band 3" }
        ]
      },
      {
        key: "osvc_activity_status",
        type: "select",
        label: "OSVC activity status",
        categories: ["self_employed"],
        resultInputKey: "osvc_activity_status",
        visibleWhen: (controlValues) => controlValues.self_employed_tax_mode === "standard",
        hint: "Selects the minimum contribution base path for main activity, secondary activity, or the reduced new-main-activity social minimum.",
        options: [
          { value: "main", label: "Main activity" },
          { value: "secondary", label: "Secondary activity" },
          { value: "new_main_activity", label: "New main activity" }
        ]
      },
      {
        key: "child_credit_claim_share",
        type: "select",
        label: "Child-credit claim share",
        categories: ["employee", "self_employed"],
        resultInputKey: "child_credit_claim_share",
        visibleWhen: standardTaxMode,
        hint: "Percentage of the annual Czech child tax credit claimed by this taxpayer when parents split the entitlement.",
        options: [
          { value: "0", label: "0%" },
          { value: "25", label: "25%" },
          { value: "50", label: "50%" },
          { value: "75", label: "75%" },
          { value: "100", label: "100%" }
        ]
      },
      {
        key: "apply_spouse_credit",
        type: "checkbox",
        label: "Apply spouse credit",
        categories: ["employee", "self_employed"],
        resultInputKey: "apply_spouse_credit",
        visibleWhen: standardTaxMode,
        hint: "Applies the dependent-spouse credit only when the spouse is below the income limit and cares for a child aged under 3."
      },
      {
        key: "spouse_income",
        type: "currency",
        label: "Spouse income",
        categories: ["employee", "self_employed"],
        resultInputKey: "spouse_income",
        visibleWhen: spouseCreditDetailsVisible,
        hint: "Annual own income of the spouse for the CZK 68,000 spouse-credit limit."
      },
      {
        key: "spouse_cares_child_under_three",
        type: "checkbox",
        label: "Spouse cares for child under 3",
        categories: ["employee", "self_employed"],
        resultInputKey: "spouse_cares_child_under_three",
        visibleWhen: spouseCreditDetailsVisible,
        hint: "Required for the current spouse credit: the dependent spouse must care for a child who is no older than 3."
      },
      {
        key: "spouse_ztp_p",
        type: "checkbox",
        label: "Spouse has ZTP/P",
        categories: ["employee", "self_employed"],
        resultInputKey: "spouse_ztp_p",
        visibleWhen: spouseCreditDetailsVisible,
        hint: "Doubles the spouse credit when the dependent spouse holds ZTP/P disability status."
      },
      {
        key: "mortgage_interest_paid",
        type: "currency",
        label: "Mortgage interest",
        categories: ["employee", "self_employed"],
        resultInputKey: "mortgage_interest_paid",
        visibleWhen: standardTaxMode,
        hint: "Eligible annual housing-loan interest; the calculator caps it at the seeded CZK 150,000 limit."
      },
      {
        key: "pension_contributions",
        type: "currency",
        label: "Pension contributions",
        categories: ["employee", "self_employed"],
        resultInputKey: "pension_contributions",
        visibleWhen: standardTaxMode,
        hint: "Eligible voluntary pension, retirement-product, or long-term-care contributions included in the shared CZK 48,000 cap."
      },
      {
        key: "life_insurance_contributions",
        type: "currency",
        label: "Life insurance contributions",
        categories: ["employee", "self_employed"],
        resultInputKey: "life_insurance_contributions",
        visibleWhen: standardTaxMode,
        hint: "Eligible private life-insurance contributions, combined with pension contributions under the shared CZK 48,000 cap."
      },
      {
        key: "donations_amount",
        type: "currency",
        label: "Donations",
        categories: ["employee", "self_employed"],
        resultInputKey: "donations_amount",
        visibleWhen: standardTaxMode,
        hint: "Eligible gifts reduce the tax base only when the minimum threshold is met and are capped at the seeded share of the tax base."
      }
    ],
    showAgeField: false,
    ageFieldHint: null,
    showChildrenCountField: true,
    childrenCountHint:
      "Used for the Czech child tax credit sequence: first child, second child, then the higher third-and-next-child amount.",
    showChildrenUnderThreeField: false,
    showDisabilityField: true,
    disabilityFieldHint:
      "Applies Czech taxpayer disability credits for invalidity degree 1/2, invalidity degree 3, or ZTP/P card status.",
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
