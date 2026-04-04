const businessDayOptions = Array.from({ length: 31 }, (_item, index) => {
  const value = String(index + 1);
  return { value, label: value };
});

const percentageOptions = (values) =>
  values.map((value) => ({
    value: String(value),
    label: `${value}%`
  }));

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
        hint: "Use 0% if the employee does not participate in PPK.",
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
        key: "lump_sum_rate",
        type: "select",
        label: "Lump-sum rate",
        categories: [ "self_employed" ],
        defaultValue: "12",
        resultInputKey: "lump_sum_rate",
        visibleWhen: (controlValues) => controlValues.b2b_tax_form === "lump_sum",
        options: percentageOptions([ 2, 3, 5.5, 8.5, 10, 12, 12.5, 14, 15, 17 ])
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
      }
    ],
    showAgeField: [ "employee" ],
    ageFieldHint:
      "For employment contracts, the under-26 bracket applies Poland's relief for young people automatically. Retirement-age relief still requires the dedicated working-senior option if you qualify.",
    showChildrenCountField: [ "employee", "self_employed" ],
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
