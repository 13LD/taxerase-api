const ADVANCED_RULE_TAX_YEAR = 2025;

function isAdvancedRuleYear(_controlValues, _selectedCategory, selectedTaxYear) {
  return Number(selectedTaxYear) === ADVANCED_RULE_TAX_YEAR;
}

function withAdvancedYearGate(control) {
  const visibleWhen = control.visibleWhen;

  return {
    ...control,
    visibleWhen: (controlValues, selectedCategory, selectedTaxYear) =>
      isAdvancedRuleYear(controlValues, selectedCategory, selectedTaxYear) &&
        (!visibleWhen || visibleWhen(controlValues, selectedCategory, selectedTaxYear))
  };
}

const creditControls = [
  {
    key: "fiscal_partner",
    type: "checkbox",
    label: "Fiscal partner",
    defaultValue: false,
    resultInputKey: "fiscal_partner"
  },
  {
    key: "partner_labour_income",
    type: "currency",
    label: "Partner labour income",
    defaultValue: "0",
    resultInputKey: "partner_labour_income",
    visibleWhen: (controlValues) => Boolean(controlValues.fiscal_partner)
  },
  {
    key: "children_under_12_count",
    type: "number",
    label: "Under-12 dependents",
    min: 0,
    step: 1,
    defaultValue: "0",
    resultInputKey: "children_under_12_count"
  },
  {
    key: "single_aow_household",
    type: "checkbox",
    label: "Single AOW household",
    defaultValue: false,
    resultInputKey: "single_aow_household"
  },
  {
    key: "wajong_status",
    type: "checkbox",
    label: "Young-disabled credit",
    defaultValue: false,
    resultInputKey: "wajong_status"
  },
  {
    key: "green_investments_value",
    type: "currency",
    label: "Green investments",
    defaultValue: "0",
    resultInputKey: "green_investments_value"
  }
];

const personalDeductionControls = [
  { key: "partner_alimony_paid", type: "currency", label: "Partner alimony paid" },
  { key: "healthcare_medicines_prescription", type: "currency", label: "Prescription medicines" },
  { key: "healthcare_aids_and_adaptations", type: "currency", label: "Healthcare aids and adaptations" },
  { key: "healthcare_transport", type: "currency", label: "Healthcare transport" },
  { key: "healthcare_diet_prescribed", type: "currency", label: "Prescribed diet costs" },
  { key: "healthcare_extra_family_help", type: "currency", label: "Extra family help" },
  { key: "healthcare_extra_clothing_bedding", type: "currency", label: "Extra clothing and bedding" },
  { key: "healthcare_other_eligible", type: "currency", label: "Other eligible healthcare" },
  { key: "temporary_home_stay_disabled_days", type: "number", label: "Disabled home-stay days", min: 0, step: 1 },
  { key: "temporary_home_stay_disabled_km", type: "number", label: "Disabled home-stay km", min: 0, step: 1 },
  { key: "ordinary_anbi_gifts", type: "currency", label: "Ordinary ANBI gifts" },
  { key: "periodic_anbi_gifts", type: "currency", label: "Periodic ANBI gifts" },
  { key: "cultural_anbi_gifts", type: "currency", label: "Cultural ANBI gifts" },
  { key: "deductible_aov_premium", type: "currency", label: "AOV premiums" },
  { key: "deductible_lijfrente_premium", type: "currency", label: "Lijfrente premiums" },
  { key: "remaining_personal_deduction_carryforward", type: "currency", label: "Personal deduction carryforward" }
].map((control) => ({
  defaultValue: "0",
  resultInputKey: control.key,
  ...control
}));

const entrepreneurControls = [
  {
    key: "qualifies_as_entrepreneur",
    type: "checkbox",
    label: "Qualifies as entrepreneur",
    categories: [ "self_employed" ],
    defaultValue: true,
    resultInputKey: "qualifies_as_entrepreneur"
  },
  {
    key: "hours_worked_in_business",
    type: "number",
    label: "Business hours",
    categories: [ "self_employed" ],
    min: 0,
    step: 1,
    defaultValue: "1225",
    resultInputKey: "hours_worked_in_business"
  },
  {
    key: "has_other_work_hours_higher_than_business",
    type: "checkbox",
    label: "Other work hours are higher",
    categories: [ "self_employed" ],
    defaultValue: false,
    resultInputKey: "has_other_work_hours_higher_than_business"
  },
  {
    key: "startup_uses_in_last_5_years",
    type: "number",
    label: "Starter deduction uses",
    categories: [ "self_employed" ],
    min: 0,
    max: 3,
    step: 1,
    defaultValue: "3",
    resultInputKey: "startup_uses_in_last_5_years"
  },
  {
    key: "disabled_starter_scheme",
    type: "checkbox",
    label: "Disabled starter scheme",
    categories: [ "self_employed" ],
    defaultValue: false,
    resultInputKey: "disabled_starter_scheme"
  },
  {
    key: "disabled_starter_deduction_uses",
    type: "number",
    label: "Disabled starter uses",
    categories: [ "self_employed" ],
    min: 0,
    max: 2,
    step: 1,
    defaultValue: "0",
    resultInputKey: "disabled_starter_deduction_uses",
    visibleWhen: (controlValues) => Boolean(controlValues.disabled_starter_scheme)
  },
  {
    key: "has_s_and_o_declaration",
    type: "checkbox",
    label: "S&O declaration",
    categories: [ "self_employed" ],
    defaultValue: false,
    resultInputKey: "has_s_and_o_declaration"
  },
  {
    key: "s_and_o_hours",
    type: "number",
    label: "S&O hours",
    categories: [ "self_employed" ],
    min: 0,
    step: 1,
    defaultValue: "0",
    resultInputKey: "s_and_o_hours",
    visibleWhen: (controlValues) => Boolean(controlValues.has_s_and_o_declaration)
  },
  {
    key: "s_and_o_starter",
    type: "checkbox",
    label: "S&O starter",
    categories: [ "self_employed" ],
    defaultValue: false,
    resultInputKey: "s_and_o_starter",
    visibleWhen: (controlValues) => Boolean(controlValues.has_s_and_o_declaration)
  },
  {
    key: "partner_unpaid_hours",
    type: "number",
    label: "Partner unpaid hours",
    categories: [ "self_employed" ],
    min: 0,
    step: 1,
    defaultValue: "0",
    resultInputKey: "partner_unpaid_hours",
    visibleWhen: (controlValues) => Boolean(controlValues.fiscal_partner)
  },
  {
    key: "partner_fee_paid",
    type: "currency",
    label: "Partner fee paid",
    categories: [ "self_employed" ],
    defaultValue: "0",
    resultInputKey: "partner_fee_paid",
    visibleWhen: (controlValues) => Boolean(controlValues.fiscal_partner)
  },
  {
    key: "business_ceased",
    type: "checkbox",
    label: "Business ceased",
    categories: [ "self_employed" ],
    defaultValue: false,
    resultInputKey: "business_ceased"
  },
  {
    key: "cessation_profit",
    type: "currency",
    label: "Cessation profit",
    categories: [ "self_employed" ],
    defaultValue: "0",
    resultInputKey: "cessation_profit",
    visibleWhen: (controlValues) => Boolean(controlValues.business_ceased)
  },
  {
    key: "stakingsaftrek_used_before",
    type: "checkbox",
    label: "Stakingsaftrek used before",
    categories: [ "self_employed" ],
    defaultValue: false,
    resultInputKey: "stakingsaftrek_used_before",
    visibleWhen: (controlValues) => Boolean(controlValues.business_ceased)
  },
  {
    key: "private_vehicle_business_km",
    type: "number",
    label: "Private vehicle business km",
    categories: [ "self_employed" ],
    min: 0,
    step: 1,
    defaultValue: "0",
    resultInputKey: "private_vehicle_business_km"
  },
  {
    key: "limited_deductible_costs_amount",
    type: "currency",
    label: "Mixed-cost amount",
    categories: [ "self_employed" ],
    defaultValue: "0",
    resultInputKey: "limited_deductible_costs_amount"
  },
  {
    key: "choose_80_percent_method",
    type: "checkbox",
    label: "Use 80% mixed-cost method",
    categories: [ "self_employed" ],
    defaultValue: false,
    resultInputKey: "choose_80_percent_method"
  },
  {
    key: "kia_basis",
    type: "currency",
    label: "KIA investment basis",
    categories: [ "self_employed" ],
    defaultValue: "0",
    resultInputKey: "kia_basis"
  },
  {
    key: "home_workspace_independent",
    type: "checkbox",
    label: "Independent home workspace",
    categories: [ "self_employed" ],
    defaultValue: false,
    resultInputKey: "home_workspace_independent"
  },
  {
    key: "home_workspace_costs",
    type: "currency",
    label: "Home workspace costs",
    categories: [ "self_employed" ],
    defaultValue: "0",
    resultInputKey: "home_workspace_costs",
    visibleWhen: (controlValues) => Boolean(controlValues.home_workspace_independent)
  },
  {
    key: "cessation_annuity_premium",
    type: "currency",
    label: "Cessation annuity premium",
    categories: [ "self_employed" ],
    defaultValue: "0",
    resultInputKey: "cessation_annuity_premium",
    visibleWhen: (controlValues) => Boolean(controlValues.business_ceased)
  }
];

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
      },
      ...creditControls.map(withAdvancedYearGate),
      ...personalDeductionControls.map(withAdvancedYearGate),
      ...entrepreneurControls.map(withAdvancedYearGate)
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
