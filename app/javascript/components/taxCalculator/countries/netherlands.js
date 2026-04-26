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
    hint:
      "Use when you have a Dutch fiscal partner. Partner income can affect selected credits and personal-deduction thresholds.",
    defaultValue: false,
    resultInputKey: "fiscal_partner"
  },
  {
    key: "partner_labour_income",
    type: "currency",
    label: "Partner labour income",
    hint:
      "Your fiscal partner's employment or business labour income. Used for income-dependent combination credit and joint deduction thresholds.",
    defaultValue: "0",
    resultInputKey: "partner_labour_income",
    visibleWhen: (controlValues) => Boolean(controlValues.fiscal_partner)
  },
  {
    key: "children_under_12_count",
    type: "number",
    label: "Under-12 dependents",
    hint:
      "Number of children under 12 used to test income-dependent combination credit eligibility.",
    min: 0,
    step: 1,
    defaultValue: "0",
    resultInputKey: "children_under_12_count"
  },
  {
    key: "single_aow_household",
    type: "checkbox",
    label: "Single AOW household",
    hint:
      "Use for an AOW-age taxpayer living as a single household; this enables the single older-person credit path.",
    defaultValue: false,
    resultInputKey: "single_aow_household"
  },
  {
    key: "wajong_status",
    type: "checkbox",
    label: "Young-disabled credit",
    hint:
      "Use when the taxpayer qualifies for the Dutch young-disabled person credit; the calculator adds the seeded credit amount.",
    defaultValue: false,
    resultInputKey: "wajong_status"
  },
  {
    key: "green_investments_value",
    type: "currency",
    label: "Green investments",
    hint:
      "Value of qualifying green investments used for the Dutch green-investment tax credit calculation.",
    defaultValue: "0",
    resultInputKey: "green_investments_value"
  }
];

const personalDeductionControls = [
  {
    key: "partner_alimony_paid",
    type: "currency",
    label: "Partner alimony paid",
    hint:
      "Maintenance paid to a former partner. The calculator treats it as a personal deduction against Box 1 taxable income."
  },
  {
    key: "healthcare_medicines_prescription",
    type: "currency",
    label: "Prescription medicines",
    hint:
      "Out-of-pocket prescribed medicine costs included in the Dutch specific healthcare-cost deduction threshold."
  },
  {
    key: "healthcare_aids_and_adaptations",
    type: "currency",
    label: "Healthcare aids and adaptations",
    hint:
      "Eligible medical aids or home adaptations paid personally. The calculator includes them in the specific healthcare-cost pool."
  },
  {
    key: "healthcare_transport",
    type: "currency",
    label: "Healthcare transport",
    hint:
      "Eligible travel or transport costs for medical care. These feed into the healthcare deduction after the income threshold."
  },
  {
    key: "healthcare_diet_prescribed",
    type: "currency",
    label: "Prescribed diet costs",
    hint:
      "Diet costs that qualify only when prescribed for medical reasons. Enter the eligible deductible amount, not normal groceries."
  },
  {
    key: "healthcare_extra_family_help",
    type: "currency",
    label: "Extra family help",
    hint:
      "Extra household or family-help costs related to illness or disability, included in the healthcare-cost deduction pool."
  },
  {
    key: "healthcare_extra_clothing_bedding",
    type: "currency",
    label: "Extra clothing and bedding",
    hint:
      "Additional clothing or bedding costs caused by illness or disability, included in the healthcare-cost deduction pool."
  },
  {
    key: "healthcare_other_eligible",
    type: "currency",
    label: "Other eligible healthcare",
    hint:
      "Other qualifying specific healthcare costs after excluding non-deductible items such as insured or reimbursed costs."
  },
  {
    key: "temporary_home_stay_disabled_days",
    type: "number",
    label: "Disabled home-stay days",
    min: 0,
    step: 1,
    hint:
      "Days of eligible temporary home stay for a disabled person. The calculator multiplies days by the seeded daily rate."
  },
  {
    key: "temporary_home_stay_disabled_km",
    type: "number",
    label: "Disabled home-stay km",
    min: 0,
    step: 1,
    hint:
      "Eligible kilometres for temporary home-stay visits for a disabled person. The calculator applies the seeded per-km rate."
  },
  {
    key: "ordinary_anbi_gifts",
    type: "currency",
    label: "Ordinary ANBI gifts",
    hint:
      "One-off gifts to a Dutch-recognized public benefit organisation (ANBI). Subject to the ordinary gift threshold and cap."
  },
  {
    key: "periodic_anbi_gifts",
    type: "currency",
    label: "Periodic ANBI gifts",
    hint:
      "Recurring ANBI gifts under a qualifying long-term arrangement. The calculator deducts these separately from ordinary gifts."
  },
  {
    key: "cultural_anbi_gifts",
    type: "currency",
    label: "Cultural ANBI gifts",
    hint:
      "Gifts to an ANBI classified as a cultural institution. The calculator includes them with ordinary gifts and adds the cultural uplift, capped at EUR 1,250."
  },
  {
    key: "deductible_aov_premium",
    type: "currency",
    label: "AOV premiums",
    hint:
      "AOV means arbeidsongeschiktheidsverzekering: private disability-insurance premiums, usually for self-employed income protection."
  },
  {
    key: "deductible_lijfrente_premium",
    type: "currency",
    label: "Lijfrente premiums",
    hint:
      "Deductible annuity pension premiums. Enter only the amount that qualifies within the Dutch pension-premium rules."
  },
  {
    key: "remaining_personal_deduction_carryforward",
    type: "currency",
    label: "Personal deduction carryforward",
    hint:
      "Unused personal deductions from prior years. The calculator applies them against current Box 1 taxable income and carries forward any remainder."
  }
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
    hint:
      "Use when the taxpayer meets Dutch entrepreneur-for-income-tax conditions. Turning it off removes entrepreneur reliefs.",
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
    hint:
      "Hours spent on the business during the year. The main Dutch hours criterion is 1,225 hours for several entrepreneur deductions.",
    defaultValue: "1225",
    resultInputKey: "hours_worked_in_business"
  },
  {
    key: "has_other_work_hours_higher_than_business",
    type: "checkbox",
    label: "Other work hours are higher",
    categories: [ "self_employed" ],
    hint:
      "Use when more time was spent on other work than on the business; this blocks the standard hours criterion in the calculator.",
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
    hint:
      "Number of times startersaftrek was already used in the previous five years. Fewer than 3 allows the starter deduction path.",
    defaultValue: "3",
    resultInputKey: "startup_uses_in_last_5_years"
  },
  {
    key: "disabled_starter_scheme",
    type: "checkbox",
    label: "Disabled starter scheme",
    categories: [ "self_employed" ],
    hint:
      "Use for the Dutch disabled-starter deduction path, which has a lower hours threshold than the standard hours criterion.",
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
    hint:
      "How many prior disabled-starter deductions were used. The first, second, and later uses have different seeded amounts.",
    defaultValue: "0",
    resultInputKey: "disabled_starter_deduction_uses",
    visibleWhen: (controlValues) => Boolean(controlValues.disabled_starter_scheme)
  },
  {
    key: "has_s_and_o_declaration",
    type: "checkbox",
    label: "S&O declaration",
    categories: [ "self_employed" ],
    hint:
      "Use when the business has an official S&O/R&D declaration. The S&O deduction also requires the minimum S&O hours.",
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
    hint:
      "Hours spent on qualifying S&O/R&D work. The calculator applies the S&O deduction only once the minimum is reached.",
    defaultValue: "0",
    resultInputKey: "s_and_o_hours",
    visibleWhen: (controlValues) => Boolean(controlValues.has_s_and_o_declaration)
  },
  {
    key: "s_and_o_starter",
    type: "checkbox",
    label: "S&O starter",
    categories: [ "self_employed" ],
    hint:
      "Use when the S&O/R&D starter increase applies; the calculator adds the seeded starter amount to the S&O deduction.",
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
    hint:
      "Unpaid hours your fiscal partner worked in the business. Used for meewerkaftrek when the partner fee stays below the cap.",
    defaultValue: "0",
    resultInputKey: "partner_unpaid_hours",
    visibleWhen: (controlValues) => Boolean(controlValues.fiscal_partner)
  },
  {
    key: "partner_fee_paid",
    type: "currency",
    label: "Partner fee paid",
    categories: [ "self_employed" ],
    hint:
      "Compensation paid to your fiscal partner for business work. Meewerkaftrek applies only when this stays below the seeded cap.",
    defaultValue: "0",
    resultInputKey: "partner_fee_paid",
    visibleWhen: (controlValues) => Boolean(controlValues.fiscal_partner)
  },
  {
    key: "business_ceased",
    type: "checkbox",
    label: "Business ceased",
    categories: [ "self_employed" ],
    hint:
      "Use when the business stopped during the year; this enables stakingsaftrek and cessation-annuity inputs.",
    defaultValue: false,
    resultInputKey: "business_ceased"
  },
  {
    key: "cessation_profit",
    type: "currency",
    label: "Cessation profit",
    categories: [ "self_employed" ],
    hint:
      "Profit arising from ending the business. The calculator uses it to cap the stakingsaftrek relief.",
    defaultValue: "0",
    resultInputKey: "cessation_profit",
    visibleWhen: (controlValues) => Boolean(controlValues.business_ceased)
  },
  {
    key: "stakingsaftrek_used_before",
    type: "checkbox",
    label: "Stakingsaftrek used before",
    categories: [ "self_employed" ],
    hint:
      "Use if the business-cessation deduction was already used before; this prevents the calculator from applying it again.",
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
    hint:
      "Business kilometres driven in a private vehicle. The calculator multiplies kilometres by the seeded per-km deduction rate.",
    defaultValue: "0",
    resultInputKey: "private_vehicle_business_km"
  },
  {
    key: "limited_deductible_costs_amount",
    type: "currency",
    label: "Mixed-cost amount",
    categories: [ "self_employed" ],
    hint:
      "Partly deductible business costs such as representation-style costs. The calculator applies either the fixed exclusion or 80% method.",
    defaultValue: "0",
    resultInputKey: "limited_deductible_costs_amount"
  },
  {
    key: "choose_80_percent_method",
    type: "checkbox",
    label: "Use 80% mixed-cost method",
    categories: [ "self_employed" ],
    hint:
      "Switches mixed costs from the fixed non-deductible amount to the seeded 80% deductible method.",
    defaultValue: false,
    resultInputKey: "choose_80_percent_method"
  },
  {
    key: "kia_basis",
    type: "currency",
    label: "KIA investment basis",
    categories: [ "self_employed" ],
    hint:
      "Qualifying small-scale investment amount for kleinschaligheidsinvesteringsaftrek (KIA). The calculator applies the seeded bands.",
    defaultValue: "0",
    resultInputKey: "kia_basis"
  },
  {
    key: "home_workspace_independent",
    type: "checkbox",
    label: "Independent home workspace",
    categories: [ "self_employed" ],
    hint:
      "Use only when the home office qualifies as an independent workspace. Otherwise home workspace costs are ignored.",
    defaultValue: false,
    resultInputKey: "home_workspace_independent"
  },
  {
    key: "home_workspace_costs",
    type: "currency",
    label: "Home workspace costs",
    categories: [ "self_employed" ],
    hint:
      "Eligible costs for a qualifying independent home workspace. Shown only when the independent workspace condition is selected.",
    defaultValue: "0",
    resultInputKey: "home_workspace_costs",
    visibleWhen: (controlValues) => Boolean(controlValues.home_workspace_independent)
  },
  {
    key: "cessation_annuity_premium",
    type: "currency",
    label: "Cessation annuity premium",
    categories: [ "self_employed" ],
    hint:
      "Annuity premium connected to business cessation. The calculator passes it to personal deductions and caps it by the seeded limit.",
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
          "Dutch expat facility for eligible inbound employees: part of salary is treated as an untaxed allowance. 2025 thresholds: €46,660 standard or €35,468 if under 30 with a master's degree.",
        categories: [ "employee" ],
        defaultValue: false,
        resultInputKey: "apply_thirty_percent_ruling",
        children: [
          {
            key: "thirty_percent_ruling_basis",
            type: "select",
            label: "30% ruling basis",
            hint:
              "Select the eligibility threshold used to test the 30% ruling salary condition. Scientific research and doctor specialist training have no salary threshold.",
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
