const countOptions = (maxValue) =>
  Array.from({ length: maxValue + 1 }, (_item, index) => {
    const value = String(index);
    return { value, label: value };
  });

const sharedCategories = [ "employee", "self_employed" ];

function buildSharedCurrencyControl({ key, label, hint }) {
  return {
    key,
    type: "currency",
    label,
    hint,
    categories: sharedCategories,
    defaultValue: "0",
    resultInputKey: key
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
].map(buildSharedCurrencyControl);

const portugalCalculatorConfig = {
  calculationEndpoint: "/api/v1/portugal/salary_calculation",
  fallbackTitle: "Portugal tax estimate",
  sectionKicker: "EU tax calculator",
  formConfig: {
    incomeLabels: {
      employee: "Gross income",
      self_employed: "Business revenue"
    },
    periodLabels: {
      employee: "Income period",
      self_employed: "Revenue period"
    },
    regimeControls: [
      {
        key: "business_activity_type",
        type: "select",
        label: "Activity type",
        hint:
          "Professional services use the 75% simplified-regime coefficient, other services use 35%, and goods or hospitality use 15%.",
        categories: [ "self_employed" ],
        defaultValue: "professional_services",
        resultInputKey: "business_activity_type",
        options: [
          { value: "professional_services", label: "Professional services" },
          { value: "other_services", label: "Other services" },
          { value: "sales_goods_hospitality", label: "Goods, hospitality, food, or beverage" }
        ]
      },
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
      ...sharedDeductionControls
    ],
    showAgeField: false,
    ageFieldHint: null,
    showChildrenCountField: true,
    showChildrenUnderThreeField: true,
    showDisabilityField: true,
    ageBracketOptions: [],
    disabilityOptions: [
      { value: "none", label: "None" },
      { value: "disability_60_plus", label: "60% disability or more" }
    ]
  }
};

export default portugalCalculatorConfig;
