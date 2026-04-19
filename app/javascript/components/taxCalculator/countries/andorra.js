const countOptions = (maxValue) =>
  Array.from({ length: maxValue + 1 }, (_item, index) => ({
    value: String(index),
    label: String(index)
  }));

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
        categories: [ "employee", "self_employed" ],
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
        categories: [ "employee", "self_employed" ],
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
        categories: [ "employee", "self_employed" ],
        defaultValue: false,
        resultInputKey: "has_spouse_or_partner",
        children: [
          {
            key: "spouse_without_income",
            type: "checkbox",
            label: "Spouse/partner has no general-base income",
            hint:
              "Use this when the spouse or stable partner has no income included in Andorra's general tax base. Savings-base income does not block this rule.",
            categories: [ "employee", "self_employed" ],
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
            categories: [ "employee", "self_employed" ],
            defaultValue: "0",
            resultInputKey: "spouse_general_income",
            visibleWhen: (controlValues) =>
              Boolean(controlValues.has_spouse_or_partner) && !controlValues.spouse_without_income
          }
        ]
      },
      {
        key: "apply_housing_rent_support",
        type: "checkbox",
        label: "Estimate housing rent support",
        hint:
          "This is a sourced housing-support estimate outside IRPF and CASS totals. Use it only if the selected-year support program applies to you.",
        categories: [ "employee", "self_employed" ],
        defaultValue: false,
        resultInputKey: "apply_housing_rent_support",
        children: [
          {
            key: "housing_support_priority_group",
            type: "checkbox",
            label: "Priority-group housing support",
            hint:
              "Use the priority-group rate only when the official housing-support program classifies the household in a priority group for the selected year.",
            categories: [ "employee", "self_employed" ],
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
            categories: [ "employee", "self_employed" ],
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
    showChildrenUnderThreeField: false,
    showDisabilityField: true,
    ageBracketOptions: [],
    disabilityOptions: [
      { value: "none", label: "None" },
      { value: "recognized_disability", label: "Recognized disability" }
    ]
  }
};

export default andorraCalculatorConfig;
