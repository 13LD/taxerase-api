const businessDayOptions = Array.from({ length: 31 }, (_item, index) => {
  const value = String(index + 1);
  return { value, label: value };
});

const percentageOptions = (values) =>
  values.map((value) => ({
    value: String(value),
    label: `${value}%`
  }));

const yearsDescending = (start, end) =>
  Array.from({ length: end - start + 1 }, (_item, index) => {
    const value = String(end - index);
    return { value, label: value };
  });

const polandCalculatorConfig = {
  calculationEndpoint: "/api/v1/poland/salary_calculation",
  fallbackTitle: "Poland tax estimate",
  sectionKicker: "EU tax calculator",
  formConfig: {
    profileLabels: {
      employee: "Contract of employment",
      self_employed: "B2B contract"
    },
    regimeControls: [
      {
        key: "revenue_cost_mode",
        type: "select",
        label: "Revenue cost",
        hint:
          "Choose the standard employee deductible-cost mode. Copyright uses the 50% author-cost path with the statutory annual cap.",
        categories: [ "employee" ],
        defaultValue: "normal",
        resultInputKey: "revenue_cost_mode",
        options: [
          { value: "normal", label: "Normal" },
          { value: "elevated", label: "Elevated" },
          { value: "copyright", label: "Copyright 50%" },
          { value: "none", label: "None" }
        ]
      },
      {
        key: "monthly_tax_relief_mode",
        type: "select",
        label: "Monthly PIT-2 tax relief",
        hint:
          "This controls the monthly share of the annual tax-reducing amount: full 300 PLN, half 150 PLN, or one-third 100 PLN.",
        categories: [ "employee" ],
        defaultValue: "full",
        resultInputKey: "monthly_tax_relief_mode",
        options: [
          { value: "full", label: "Full relief" },
          { value: "half", label: "1/2 relief" },
          { value: "third", label: "1/3 relief" },
          { value: "none", label: "No relief" }
        ]
      },
      {
        key: "ppk_employee_rate",
        type: "select",
        label: "PPK employee contribution",
        hint:
          "Employee share of PPK, Poland's employee capital-plan pension saving program. Use 0% if the employee does not participate.",
        categories: [ "employee" ],
        defaultValue: "0",
        resultInputKey: "ppk_employee_rate",
        options: percentageOptions([ 0, 0.5, 2, 3, 4 ])
      },
      {
        key: "ppk_employer_rate",
        type: "select",
        label: "PPK employer contribution",
        hint: "The statutory basic employer contribution is 1.5%. Additional contributions can raise it up to 4%.",
        categories: [ "employee" ],
        defaultValue: "0",
        resultInputKey: "ppk_employer_rate",
        options: percentageOptions([ 0, 1.5, 2, 3, 4 ])
      },
      {
        key: "employer_accident_rate",
        type: "select",
        label: "Employer accident rate",
        hint:
          "The default small-employer rate is 1.67%. The regulation allows different rates by risk class.",
        categories: [ "employee" ],
        defaultValue: "1.67",
        resultInputKey: "employer_accident_rate",
        options: percentageOptions([ 0.67, 1.67, 3.33 ])
      },
      {
        key: "include_labor_fund",
        type: "checkbox",
        label: "Include Labor Fund",
        hint: "The Labor Fund contribution is 2.45% of the contribution base when it applies.",
        categories: [ "employee" ],
        defaultValue: true,
        resultInputKey: "include_labor_fund"
      },
      {
        key: "include_fgsp",
        type: "checkbox",
        label: "Include FGŚP",
        hint: "The Guaranteed Employee Benefits Fund contribution is 0.1% of the contribution base when it applies.",
        categories: [ "employee" ],
        defaultValue: true,
        resultInputKey: "include_fgsp"
      },
      {
        key: "b2b_tax_form",
        type: "select",
        label: "Taxation form",
        hint:
          "Select the B2B income-tax regime: progressive tax scale, 19% flat tax, or revenue-based lump sum.",
        categories: [ "self_employed" ],
        defaultValue: "tax_scale",
        resultInputKey: "b2b_tax_form",
        options: [
          { value: "tax_scale", label: "Tax scale (12% / 32%)" },
          { value: "flat_tax", label: "Flat tax (19%)" },
          { value: "lump_sum", label: "Lump sum" }
        ]
      },
      {
        key: "lump_sum_activity_type",
        type: "select",
        label: "Lump-sum activity",
        hint:
          "Maps the business activity to the seeded ryczalt revenue-tax rate, such as 12% for IT services or 3% for trade and gastronomy.",
        categories: [ "self_employed" ],
        defaultValue: "it_services",
        resultInputKey: "lump_sum_activity_type",
        visibleWhen: (controlValues) => controlValues.b2b_tax_form === "lump_sum",
        options: [
          { value: "professional_services", label: "Professional services (17%)" },
          { value: "healthcare", label: "Healthcare (14%)" },
          { value: "it_services", label: "IT services (12%)" },
          { value: "general_services", label: "General services (8.5%)" },
          { value: "manufacturing_construction", label: "Manufacturing / construction (5.5%)" },
          { value: "trade_gastronomy", label: "Trade / gastronomy (3%)" }
        ]
      },
      {
        key: "social_insurance_mode",
        type: "select",
        label: "Social insurance",
        hint:
          "Choose the ZUS relief path that applies to the business. Small ZUS Plus uses the previous-year average monthly income field below.",
        categories: [ "self_employed" ],
        defaultValue: "standard",
        resultInputKey: "social_insurance_mode",
        options: [
          { value: "start_relief", label: "Start relief" },
          { value: "preferential", label: "Preferential contribution" },
          { value: "small_zus_plus", label: "Small ZUS Plus" },
          { value: "standard", label: "No relief" }
        ]
      },
      {
        key: "cooperating_person",
        type: "checkbox",
        label: "Cooperating person",
        hint:
          "Use this when ZUS should be calculated for a cooperating family member or similar status, which uses the standard contribution base instead of start-up relief.",
        categories: [ "self_employed" ],
        defaultValue: false,
        resultInputKey: "cooperating_person"
      },
      {
        key: "months_since_business_start",
        type: "number",
        label: "Months since business start",
        hint:
          "Lets the calculator choose start relief for the first 6 months and preferential ZUS for months 7-30 before falling back to the selected ZUS mode.",
        categories: [ "self_employed" ],
        defaultValue: "37",
        min: 0,
        step: 1,
        resultInputKey: "months_since_business_start"
      },
      {
        key: "previous_year_average_monthly_income",
        type: "currency",
        label: "Previous-year average monthly income",
        hint:
          "Used only for Small ZUS Plus to estimate the social-contribution base. Enter the average monthly income from the previous year.",
        categories: [ "self_employed" ],
        defaultValue: "12000",
        resultInputKey: "previous_year_average_monthly_income",
        visibleWhen: (controlValues) => controlValues.social_insurance_mode === "small_zus_plus"
      },
      {
        key: "include_sickness_contribution",
        type: "checkbox",
        label: "Include sickness contribution",
        hint:
          "Optional ZUS sickness insurance for B2B taxpayers. Turning it off removes that social-insurance component.",
        categories: [ "self_employed" ],
        defaultValue: true,
        resultInputKey: "include_sickness_contribution",
        visibleWhen: (controlValues) => controlValues.social_insurance_mode !== "start_relief"
      },
      {
        key: "business_days_in_month",
        type: "select",
        label: "Number of business days in month",
        hint:
          "When the period is monthly, fixed ZUS contributions are prorated by business days for a simple first-month estimate.",
        categories: [ "self_employed" ],
        defaultValue: "30",
        resultInputKey: "business_days_in_month",
        options: businessDayOptions
      },
      {
        key: "apply_return_relief",
        type: "checkbox",
        label: "Apply return relief",
        hint:
          "Use this only if you qualify for Poland's return relief. The calculator applies the shared PIT exemption cap used by this relief family.",
        categories: [ "employee", "self_employed" ],
        defaultValue: false,
        resultInputKey: "apply_return_relief"
      },
      {
        key: "return_relief_prior_non_resident",
        type: "checkbox",
        label: "Prior non-residence",
        hint:
          "Return relief requires a qualifying period of non-residence before moving Polish tax residence back to Poland.",
        categories: [ "employee", "self_employed" ],
        defaultValue: false,
        resultInputKey: "return_relief_prior_non_resident",
        visibleWhen: (controlValues) => Boolean(controlValues.apply_return_relief)
      },
      {
        key: "return_relief_year",
        type: "select",
        label: "Return relief year",
        hint:
          "Select which of the four eligible tax years after return this estimate represents.",
        categories: [ "employee", "self_employed" ],
        defaultValue: "1",
        resultInputKey: "return_relief_year",
        visibleWhen: (controlValues) => Boolean(controlValues.apply_return_relief),
        options: [
          { value: "1", label: "Year 1" },
          { value: "2", label: "Year 2" },
          { value: "3", label: "Year 3" },
          { value: "4", label: "Year 4" }
        ]
      },
      {
        key: "apply_family_4plus_relief",
        type: "checkbox",
        label: "Apply family 4+ relief",
        hint:
          "Use this only if you qualify for Poland's family 4+ PIT exemption. This requires at least 4 children and uses the shared annual PIT exemption cap for this relief family.",
        categories: [ "employee", "self_employed" ],
        defaultValue: false,
        resultInputKey: "apply_family_4plus_relief"
      },
      {
        key: "apply_working_senior_relief",
        type: "checkbox",
        label: "Apply working senior relief",
        hint:
          "Use this only if you qualify for Poland's working-senior PIT exemption. This requires retirement age or older and uses the shared annual PIT exemption cap for this relief family.",
        categories: [ "employee", "self_employed" ],
        defaultValue: false,
        resultInputKey: "apply_working_senior_relief"
      },
      {
        key: "working_senior_receives_pension",
        type: "checkbox",
        label: "Receiving pension",
        hint:
          "Working-senior relief is available only when the taxpayer has reached retirement age but is not receiving the pension covered by the exclusion.",
        categories: [ "employee", "self_employed" ],
        defaultValue: false,
        resultInputKey: "working_senior_receives_pension",
        visibleWhen: (controlValues) => Boolean(controlValues.apply_working_senior_relief)
      },
      {
        key: "birth_year",
        type: "select",
        label: "Birth year",
        hint:
          "Used with the income-type selector to test relief for young people more directly than the broad age bucket.",
        categories: [ "employee" ],
        defaultValue: "2000",
        resultInputKey: "birth_year",
        options: yearsDescending(1940, 2010)
      },
      {
        key: "young_worker_relief_income_type",
        type: "select",
        label: "Young-relief income type",
        hint:
          "Relief for young people applies to qualifying employment-style income; choose other when the income should not receive the under-26 exemption.",
        categories: [ "employee" ],
        defaultValue: "employment",
        resultInputKey: "young_worker_relief_income_type",
        options: [
          { value: "employment", label: "Employment income" },
          { value: "other", label: "Other income" }
        ]
      },
      {
        key: "filing_status",
        type: "select",
        label: "Filing status",
        hint:
          "Applies a simplified individual, joint-spouse, or single-parent tax calculation before child relief.",
        categories: [ "employee" ],
        defaultValue: "individual",
        resultInputKey: "filing_status",
        options: [
          { value: "individual", label: "Individual" },
          { value: "joint_spouse", label: "Joint with spouse" },
          { value: "single_parent", label: "Single parent" }
        ]
      },
      {
        key: "spouse_income",
        type: "currency",
        label: "Spouse income",
        hint:
          "Annual spouse income used for the simplified joint-spouse quotient and married household child-relief threshold.",
        categories: [ "employee" ],
        defaultValue: "0",
        resultInputKey: "spouse_income",
        visibleWhen: (controlValues) =>
          controlValues.filing_status === "joint_spouse" ||
          controlValues.child_relief_household_status === "married"
      },
      {
        key: "child_relief_household_status",
        type: "select",
        label: "Child-relief household",
        hint:
          "Controls the one-child income threshold: single taxpayers use the lower threshold, while married and single-parent households use the household threshold.",
        categories: [ "employee" ],
        defaultValue: "single",
        resultInputKey: "child_relief_household_status",
        options: [
          { value: "single", label: "Single" },
          { value: "married", label: "Married household" },
          { value: "single_parent", label: "Single-parent household" }
        ]
      },
      {
        key: "child_relief_household_income",
        type: "currency",
        label: "Child-relief household income",
        hint:
          "Annual income tested against the one-child limit. Leave 0 only when you want the backend to infer it from taxpayer income and spouse income.",
        categories: [ "employee" ],
        defaultValue: "",
        resultInputKey: "child_relief_household_income"
      },
      {
        key: "child_relief_claim_share",
        type: "select",
        label: "Child-relief claim share",
        hint:
          "Percentage of the annual child relief claimed by this taxpayer, useful when parents split the claim.",
        categories: [ "employee" ],
        defaultValue: "100",
        resultInputKey: "child_relief_claim_share",
        options: percentageOptions([ 0, 25, 50, 75, 100 ])
      }
    ],
    showAgeField: [ "employee" ],
    ageFieldHint:
      "For employment contracts, the under-26 bracket applies Poland's relief for young people automatically. Retirement-age relief still requires the dedicated working-senior option if you qualify.",
    showChildrenCountField: [ "employee", "self_employed" ],
    childrenCountHint:
      "Used for Poland's child relief on PIT-scale income and to validate family 4+ relief eligibility.",
    showChildrenUnderThreeField: false,
    showDisabilityField: false,
    ageBracketOptions: [
      { value: "under_26", label: "Under 26" },
      { value: "age_26_to_retirement", label: "26 to retirement age" },
      { value: "retirement_age_or_older", label: "Retirement age or older" }
    ]
  }
};

export default polandCalculatorConfig;
