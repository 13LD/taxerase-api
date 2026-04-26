const countOptions = (maxValue) =>
  Array.from({ length: maxValue + 1 }, (_item, index) => {
    const value = String(index);
    return { value, label: value };
  });

const sharedCategories = [ "employee", "self_employed" ];

function currencyControl({ key, label, hint, categories = sharedCategories }) {
  return {
    key,
    type: "currency",
    label,
    hint,
    categories,
    defaultValue: "0",
    resultInputKey: key
  };
}

function selectControl({ key, label, hint, defaultValue, options, categories = sharedCategories, visibleWhen }) {
  return {
    key,
    type: "select",
    label,
    hint,
    categories,
    defaultValue,
    resultInputKey: key,
    options,
    visibleWhen
  };
}

const sharedDeductionControls = [
  {
    key: "general_family_expenses",
    label: "General family expenses",
    hint: "Portugal grants 35% of eligible general family expenses, capped at EUR 250 per taxpayer."
  },
  {
    key: "health_expenses",
    label: "Health expenses",
    hint: "Portugal grants 15% of eligible health expenses, capped at EUR 1,000."
  },
  {
    key: "education_expenses",
    label: "Education expenses",
    hint: "Portugal grants 30% of eligible education expenses, capped at EUR 800."
  },
  {
    key: "housing_rent",
    label: "Eligible housing rent",
    hint: "Portugal grants 15% of eligible permanent-home rent, capped at EUR 800."
  },
  {
    key: "alimony_paid",
    label: "Court-ordered alimony paid",
    hint: "Portugal grants 20% of eligible alimony payments."
  },
  {
    key: "care_home_expenses",
    label: "Care home expenses",
    hint: "Portugal grants 25% of eligible care-home costs, capped at EUR 403.75."
  },
  {
    key: "domestic_work_expenses",
    label: "Domestic work remuneration",
    hint: "Portugal grants 5% of declared domestic-work pay, capped at EUR 200."
  }
].map(currencyControl);

const pprAgeBandOptions = [
  { value: "under_35", label: "Under 35" },
  { value: "from_35_to_50", label: "35 to 50" },
  { value: "over_50", label: "Over 50" }
];

const sharedPortugalControls = [
  selectControl({
    key: "filing_status",
    label: "Filing status",
    hint:
      "Individual taxes the entered income directly. Joint filing applies Portugal's household quotient by splitting the entered taxable income in half, calculating IRS, then doubling it.",
    defaultValue: "individual",
    options: [
      { value: "individual", label: "Individual" },
      { value: "joint", label: "Joint household quotient" }
    ]
  }),
  {
    key: "apply_irs_jovem",
    type: "checkbox",
    label: "Apply IRS Jovem",
    hint:
      "Use only when the taxpayer qualifies for Portugal's young-worker IRS relief. The calculator exempts part of category A/B taxable income from 2025 onward, subject to the seeded cap.",
    categories: sharedCategories,
    defaultValue: false,
    resultInputKey: "apply_irs_jovem",
    children: [
      selectControl({
        key: "irs_jovem_year",
        label: "IRS Jovem benefit year",
        hint:
          "Select the numbered year of IRS Jovem entitlement: year 1 receives the largest exemption, then the exemption percentage steps down across later years.",
        defaultValue: "1",
        options: countOptions(10).slice(1),
        visibleWhen: (controlValues) => Boolean(controlValues.apply_irs_jovem)
      })
    ]
  },
  selectControl({
    key: "young_dependents_second_later_under_six_count",
    label: "2nd+ dependants up to age 6",
    hint:
      "Counts second and later dependants who qualify for Portugal's extra young-child deduction up to age 6. Do not include the first child in this field.",
    defaultValue: "0",
    options: countOptions(6)
  }),
  currencyControl({
    key: "vat_invoice_expenses",
    label: "VAT-invoice incentive expenses",
    hint:
      "Eligible e-Fatura sectors can create a VAT-invoice deduction. The calculator only applies it when the validation state below is marked validated."
  }),
  selectControl({
    key: "vat_invoice_validation_state",
    label: "VAT invoice proof state",
    hint:
      "Validated means the invoice-backed expense is accepted in the estimate. Pending or not validated keeps the entered VAT-invoice amount out of the deduction.",
    defaultValue: "not_validated",
    options: [
      { value: "not_validated", label: "Not validated" },
      { value: "pending", label: "Pending validation" },
      { value: "validated", label: "Validated" }
    ]
  }),
  currencyControl({
    key: "disability_rehabilitation_expenses",
    label: "Disability rehabilitation expenses",
    hint:
      "Use for qualifying disability rehabilitation costs. This is separate from the taxpayer disability status selector, which applies the fixed disability deduction."
  }),
  currencyControl({
    key: "disability_insurance_premiums",
    label: "Disability insurance premiums",
    hint:
      "Premiums for qualifying disability insurance can create a capped deduction. Leave 0 for ordinary health insurance or non-qualifying cover."
  }),
  currencyControl({
    key: "ppr_contributions",
    label: "PPR contributions",
    hint:
      "Annual contributions to eligible Portuguese retirement savings plans can create a capped deduction based on the taxpayer age band."
  }),
  selectControl({
    key: "ppr_age_band",
    label: "PPR age band",
    hint:
      "Portugal caps the PPR deduction differently by age. Choose the taxpayer age band used for the PPR contribution year.",
    defaultValue: "under_35",
    options: pprAgeBandOptions
  }),
  currencyControl({
    key: "donations",
    label: "Eligible donations",
    hint:
      "Use only for donations that qualify for Portugal's IRS deduction. The calculator applies the seeded deduction percentage to the entered amount."
  })
];

const employeeControls = [
  currencyControl({
    key: "union_dues",
    label: "Union dues",
    hint:
      "Employee union dues can increase Portugal's category A specific deduction, limited by a percentage of gross employment income.",
    categories: [ "employee" ]
  }),
  currencyControl({
    key: "professional_order_dues",
    label: "Professional-order dues",
    hint:
      "Mandatory dues paid to a professional order can increase the employee specific deduction when they relate to the employment activity.",
    categories: [ "employee" ]
  })
];

const selfEmployedControls = [
  selectControl({
    key: "self_employed_tax_regime",
    label: "Category B tax regime",
    hint:
      "Simplified uses statutory revenue coefficients. Organized accounting estimates taxable profit from entered revenue, expenses, and social security.",
    categories: [ "self_employed" ],
    defaultValue: "simplified",
    options: [
      { value: "simplified", label: "Simplified regime" },
      { value: "organized_accounting", label: "Organized accounting estimate" }
    ]
  }),
  selectControl({
    key: "start_activity_year",
    label: "Start-of-activity year",
    hint:
      "For simplified-regime estimates, first- and second-year options reduce the taxable coefficient. Use none when the activity is not in its startup period.",
    categories: [ "self_employed" ],
    defaultValue: "none",
    options: [
      { value: "none", label: "No startup reduction" },
      { value: "first_year", label: "First year" },
      { value: "second_year", label: "Second year" }
    ],
    visibleWhen: (controlValues) => controlValues.self_employed_tax_regime !== "organized_accounting"
  }),
  {
    key: "social_security_exemption",
    type: "checkbox",
    label: "Self-employed Social Security exemption",
    hint:
      "Use only when the independent-worker contribution is exempt for the estimate period. When enabled, the calculator sets the annual contribution to 0.",
    categories: [ "self_employed" ],
    defaultValue: false,
    resultInputKey: "social_security_exemption"
  },
  selectControl({
    key: "social_security_adjustment_mode",
    label: "Social Security adjustment",
    hint:
      "Approximates Portugal's quarterly option to keep the standard contribution base, reduce it by 25%, or increase it by 25%.",
    categories: [ "self_employed" ],
    defaultValue: "standard",
    options: [
      { value: "standard", label: "Standard base" },
      { value: "reduce_25", label: "Reduce base by 25%" },
      { value: "increase_25", label: "Increase base by 25%" }
    ],
    visibleWhen: (controlValues) => !controlValues.social_security_exemption
  })
];

const portugalCalculatorConfig = {
  calculationEndpoint: "/api/v1/portugal/salary_calculation",
  fallbackTitle: "Portugal tax estimate",
  sectionKicker: "EU tax calculator",
  formConfig: {
    regimeControls: [
      {
        key: "ascendants_count",
        type: "select",
        label: "Ascendants in household",
        hint:
          "Use this only for ascendants living with you whose income stays within the legal limit.",
        categories: [ "employee", "self_employed" ],
        defaultValue: "0",
        resultInputKey: "ascendants_count",
        options: countOptions(3)
      },
      ...sharedPortugalControls,
      ...employeeControls,
      ...selfEmployedControls,
      {
        key: "business_activity_type",
        type: "select",
        label: "Activity type",
        hint:
          "Professional services, other services, and goods or hospitality use different simplified-regime coefficients and Social Security relevant-income rates.",
        categories: [ "self_employed" ],
        defaultValue: "professional_services",
        resultInputKey: "business_activity_type",
        options: [
          { value: "professional_services", label: "Professional services" },
          { value: "other_services", label: "Other services" },
          { value: "sales_goods_hospitality", label: "Goods, hospitality, food, or beverage" }
        ]
      },
      ...sharedDeductionControls
    ],
    showAgeField: false,
    ageFieldHint: null,
    showChildrenCountField: true,
    childrenCountHint:
      "Counts dependants for Portugal's fixed dependent deduction before IRS is finalized.",
    showChildrenUnderThreeField: true,
    childrenUnderThreeHint:
      "Subset of dependants under 3. Portugal adds the under-three dependent bonus for each child in this group.",
    showDisabilityField: true,
    disabilityFieldHint:
      "Applies Portugal's taxpayer disability deduction when recognized disability is 60% or more.",
    ageBracketOptions: [],
    disabilityOptions: [
      { value: "none", label: "None" },
      { value: "disability_60_plus", label: "60% disability or more" }
    ]
  }
};

export default portugalCalculatorConfig;
