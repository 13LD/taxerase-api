const countOptions = (maxValue) =>
  Array.from({ length: maxValue + 1 }, (_item, index) => ({
    value: String(index),
    label: String(index)
  }));

const sharedCategories = [ "employee", "self_employed" ];

function currencyControl({ key, label, hint }) {
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

const andorraCalculatorConfig = {
  calculationEndpoint: "/api/v1/andorra/salary_calculation",
  fallbackTitle: "Andorra tax estimate",
  sectionKicker: "European tax calculator",
  formConfig: {
    regimeControls: [
      {
        key: "self_employed_social_security_regime",
        type: "select",
        label: "Self-employed CASS regime",
        hint:
          "Standard uses the seeded own-account income-band ratios. The under-35 special regime uses 55% of the official minimum salary during the first 24 months.",
        categories: [ "self_employed" ],
        defaultValue: "standard",
        resultInputKey: "self_employed_social_security_regime",
        options: [
          { value: "standard", label: "Standard own-account regime" },
          { value: "under_35_first_12_months", label: "Under 35: months 1 to 12" },
          { value: "under_35_month_13_to_24", label: "Under 35: months 13 to 24" }
        ]
      },
      {
        key: "ascendants_count",
        type: "select",
        label: "Dependent ascendants",
        hint: "Use this for dependent ascendants eligible for the Andorran family reduction.",
        categories: sharedCategories,
        defaultValue: "0",
        resultInputKey: "ascendants_count",
        options: countOptions(3)
      },
      {
        key: "disabled_dependents_count",
        type: "select",
        label: "Disabled dependants",
        hint:
          "Counts dependants already included in children or ascendants whose disability status increases the Andorran family reduction by 50%.",
        categories: sharedCategories,
        defaultValue: "0",
        resultInputKey: "disabled_dependents_count",
        options: countOptions(3)
      },
      {
        key: "has_spouse_or_partner",
        type: "checkbox",
        label: "Include spouse or stable partner",
        hint:
          "Turn this on only when spouse or stable-partner rules are relevant to the personal minimum.",
        categories: sharedCategories,
        defaultValue: false,
        resultInputKey: "has_spouse_or_partner",
        children: [
          {
            key: "spouse_without_income",
            type: "checkbox",
            label: "Spouse/partner has no general-base income",
            hint:
              "Use this when the spouse or stable partner has no income included in Andorra's general tax base. Savings-base income does not block this rule.",
            categories: sharedCategories,
            defaultValue: false,
            resultInputKey: "spouse_without_income",
            visibleWhen: (controlValues) => Boolean(controlValues.has_spouse_or_partner)
          },
          {
            key: "spouse_general_income",
            type: "currency",
            label: "Spouse/partner annual general-base income",
            hint:
              "Enter the spouse or partner's net general-base income after deductible expenses. This is used for the source-backed phase-in of the personal minimum.",
            categories: sharedCategories,
            defaultValue: "0",
            resultInputKey: "spouse_general_income",
            visibleWhen: (controlValues) =>
              Boolean(controlValues.has_spouse_or_partner) && !controlValues.spouse_without_income
          }
        ]
      },
      currencyControl({
        key: "home_acquisition_investment",
        label: "Habitual-home acquisition paid",
        hint:
          "Eligible habitual-home acquisition amounts are applied as a base reduction using the selected tax year's official rate and cap."
      }),
      currencyControl({
        key: "affordable_rental_housing_investment",
        label: "Affordable-rental housing investment",
        hint:
          "Use only for qualifying property investment destined for affordable permanent-residence rental. The calculator applies the selected year's seeded cap."
      }),
      currencyControl({
        key: "higher_education_tuition",
        label: "Higher-education tuition",
        hint:
          "Tuition paid for qualifying descendants is capped by the selected year's Andorran IRPF education reduction."
      }),
      currencyControl({
        key: "pension_contributions",
        label: "Pension contributions",
        hint:
          "Qualifying pension and social-provision contributions are limited by the annual cap and 30% net-income cap."
      }),
      currencyControl({
        key: "alimony_paid",
        label: "Court-backed alimony paid",
        hint:
          "Use only for compensatory pension or food annuities paid under the supported legal or court-backed arrangements."
      }),
      {
        key: "apply_housing_rent_support",
        type: "checkbox",
        label: "Estimate housing rent support",
        hint:
          "This is a sourced housing-support estimate outside IRPF and CASS totals. Use it only if the selected-year support program applies to you.",
        categories: sharedCategories,
        defaultValue: false,
        resultInputKey: "apply_housing_rent_support",
        children: [
          {
            key: "housing_support_priority_group",
            type: "checkbox",
            label: "Priority-group housing support",
            hint:
              "Use the priority-group rate only when the official housing-support program classifies the household in a priority group for the selected year.",
            categories: sharedCategories,
            defaultValue: false,
            resultInputKey: "housing_support_priority_group",
            visibleWhen: (controlValues) => Boolean(controlValues.apply_housing_rent_support)
          },
          {
            key: "housing_rent",
            type: "currency",
            label: "Annual housing rent",
            hint:
              "Used only for the separate housing-support estimate. It does not change IRPF or CASS totals.",
            categories: sharedCategories,
            defaultValue: "0",
            resultInputKey: "housing_rent",
            visibleWhen: (controlValues) => Boolean(controlValues.apply_housing_rent_support)
          }
        ]
      }
    ],
    showAgeField: false,
    ageFieldHint: null,
    showChildrenCountField: true,
    childrenCountHint:
      "Counts dependent children for Andorra's dependent reduction. Disabled dependants can receive a separate uplift.",
    showChildrenUnderThreeField: false,
    showDisabilityField: true,
    disabilityFieldHint:
      "Applies Andorra's higher taxpayer personal reduction for recognized disability.",
    ageBracketOptions: [],
    disabilityOptions: [
      { value: "none", label: "None" },
      { value: "recognized_disability", label: "Recognized disability" }
    ]
  }
};

export default andorraCalculatorConfig;
