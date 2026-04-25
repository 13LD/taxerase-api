const countOptions = (maxValue) =>
  Array.from({ length: maxValue + 1 }, (_item, index) => ({
    value: String(index),
    label: String(index)
  }));

const visibleUnlessEmployeeBeckham = (controlValues, selectedCategory) =>
  selectedCategory !== "employee" || !controlValues.apply_beckham_law;

function currencyControl({ key, label, categories, hint, visibleWhen = visibleUnlessEmployeeBeckham }) {
  return {
    key,
    type: "currency",
    label,
    hint,
    categories,
    defaultValue: "0",
    resultInputKey: key,
    visibleWhen
  };
}

const spainCalculatorConfig = {
  calculationEndpoint: "/api/v1/spain/salary_calculation",
  fallbackTitle: "Spain tax estimate",
  sectionKicker: "EU tax calculator",
  formConfig: {
    regimeControls: [
      {
        key: "apply_beckham_law",
        type: "checkbox",
        label: "Apply Beckham Law",
        hint:
          "Article 93 special regime for eligible inbound workers. Employment income is taxed at national special-regime rates instead of the ordinary regional IRPF scale, generally for the arrival year plus five more years.",
        categories: [ "employee" ],
        defaultValue: false,
        effects: {
          regimeCategoryOverride: "special_regime",
          incomeLabel: "Gross income",
          hidePersonalReliefFields: true
        }
      },
      {
        key: "contribution_group",
        type: "select",
        label: "Contribution group",
        hint: "Stored for payroll context. The current estimate applies the shared general worker rate and base caps.",
        categories: [ "employee" ],
        defaultValue: "general",
        resultInputKey: "contribution_group",
        visibleWhen: visibleUnlessEmployeeBeckham,
        options: [
          { value: "general", label: "General workers" },
          { value: "engineers_graduates", label: "Engineers and graduates" },
          { value: "administrative", label: "Administrative workers" }
        ]
      },
      {
        key: "ascendants_count",
        type: "select",
        label: "Dependent ascendants",
        categories: [ "employee", "self_employed" ],
        defaultValue: "0",
        resultInputKey: "ascendants_count",
        visibleWhen: visibleUnlessEmployeeBeckham,
        options: countOptions(4)
      },
      {
        key: "ascendants_over_75_count",
        type: "select",
        label: "Ascendants over 75",
        categories: [ "employee", "self_employed" ],
        defaultValue: "0",
        resultInputKey: "ascendants_over_75_count",
        visibleWhen: visibleUnlessEmployeeBeckham,
        options: countOptions(4)
      },
      {
        key: "ascendant_disability_33_count",
        type: "select",
        label: "Ascendants disability 33% to 64%",
        categories: [ "employee", "self_employed" ],
        defaultValue: "0",
        resultInputKey: "ascendant_disability_33_count",
        visibleWhen: visibleUnlessEmployeeBeckham,
        options: countOptions(4)
      },
      {
        key: "ascendant_disability_65_count",
        type: "select",
        label: "Ascendants disability 65%+",
        categories: [ "employee", "self_employed" ],
        defaultValue: "0",
        resultInputKey: "ascendant_disability_65_count",
        visibleWhen: visibleUnlessEmployeeBeckham,
        options: countOptions(4)
      },
      {
        key: "ascendant_disability_support_count",
        type: "select",
        label: "Ascendants needing support",
        categories: [ "employee", "self_employed" ],
        defaultValue: "0",
        resultInputKey: "ascendant_disability_support_count",
        visibleWhen: visibleUnlessEmployeeBeckham,
        options: countOptions(4)
      },
      {
        key: "joint_filing_mode",
        type: "select",
        label: "Joint filing",
        categories: [ "employee", "self_employed" ],
        defaultValue: "none",
        resultInputKey: "joint_filing_mode",
        visibleWhen: visibleUnlessEmployeeBeckham,
        options: [
          { value: "none", label: "Individual filing" },
          { value: "married_unit", label: "Married family unit" },
          { value: "single_parent_unit", label: "Single-parent family unit" }
        ]
      },
      currencyControl({
        key: "union_dues",
        label: "Union dues",
        categories: [ "employee" ],
        hint: "Deductible employment expense."
      }),
      currencyControl({
        key: "professional_fees",
        label: "Compulsory professional fees",
        categories: [ "employee" ],
        hint: "Capped deductible employment expense."
      }),
      currencyControl({
        key: "legal_defense_costs",
        label: "Labor legal-defense costs",
        categories: [ "employee" ],
        hint: "Capped deductible employment expense for labor disputes."
      }),
      {
        key: "disabled_worker_status",
        type: "select",
        label: "Disabled worker expense",
        categories: [ "employee" ],
        defaultValue: "none",
        resultInputKey: "disabled_worker_status",
        visibleWhen: visibleUnlessEmployeeBeckham,
        options: [
          { value: "none", label: "No additional expense" },
          { value: "level_33_to_64", label: "33% to 64%" },
          { value: "level_65_plus_or_support", label: "65%+ or support needs" }
        ]
      },
      {
        key: "geographic_mobility",
        type: "checkbox",
        label: "Apply geographic mobility expense",
        categories: [ "employee" ],
        defaultValue: false,
        resultInputKey: "geographic_mobility",
        visibleWhen: visibleUnlessEmployeeBeckham
      },
      {
        key: "large_family_category",
        type: "select",
        label: "Large-family deduction",
        categories: [ "employee", "self_employed" ],
        defaultValue: "none",
        resultInputKey: "large_family_category",
        visibleWhen: visibleUnlessEmployeeBeckham,
        options: [
          { value: "none", label: "No large-family deduction" },
          { value: "general", label: "General category" },
          { value: "special", label: "Special category" }
        ]
      },
      {
        key: "large_family_extra_children",
        type: "select",
        label: "Extra children in large family",
        categories: [ "employee", "self_employed" ],
        defaultValue: "0",
        resultInputKey: "large_family_extra_children",
        visibleWhen: visibleUnlessEmployeeBeckham,
        options: countOptions(6)
      },
      {
        key: "single_parent_two_children",
        type: "checkbox",
        label: "Single parent with two children",
        categories: [ "employee", "self_employed" ],
        defaultValue: false,
        resultInputKey: "single_parent_two_children",
        visibleWhen: visibleUnlessEmployeeBeckham
      },
      {
        key: "maternity_eligible_months",
        type: "select",
        label: "Maternity deduction months",
        categories: [ "employee", "self_employed" ],
        defaultValue: "0",
        resultInputKey: "maternity_eligible_months",
        visibleWhen: visibleUnlessEmployeeBeckham,
        options: countOptions(12)
      },
      currencyControl({
        key: "nursery_expenses_paid",
        label: "Nursery expenses paid",
        categories: [ "employee", "self_employed" ],
        hint: "Additional maternity deduction increment, capped annually."
      }),
      {
        key: "disabled_descendants_count",
        type: "select",
        label: "Disabled descendants in charge",
        categories: [ "employee", "self_employed" ],
        defaultValue: "0",
        resultInputKey: "disabled_descendants_count",
        visibleWhen: visibleUnlessEmployeeBeckham,
        options: countOptions(6)
      },
      {
        key: "disabled_ascendants_count",
        type: "select",
        label: "Disabled ascendants in charge",
        categories: [ "employee", "self_employed" ],
        defaultValue: "0",
        resultInputKey: "disabled_ascendants_count",
        visibleWhen: visibleUnlessEmployeeBeckham,
        options: countOptions(6)
      },
      {
        key: "spouse_disability_dependant",
        type: "checkbox",
        label: "Spouse with disability in charge",
        categories: [ "employee", "self_employed" ],
        defaultValue: false,
        resultInputKey: "spouse_disability_dependant",
        visibleWhen: visibleUnlessEmployeeBeckham
      },
      {
        key: "self_employed_estimation_method",
        type: "select",
        label: "Self-employed estimation method",
        categories: [ "self_employed" ],
        defaultValue: "direct_simplified",
        resultInputKey: "self_employed_estimation_method",
        options: [
          { value: "direct_simplified", label: "Direct estimation simplified" },
          { value: "direct_normal", label: "Direct normal" },
          { value: "modules", label: "Modules estimate" }
        ]
      },
      currencyControl({
        key: "home_office_supply_expenses",
        label: "Home-office supply expenses",
        categories: [ "self_employed" ],
        hint: "Uses the 30% x business-use-area approach."
      }),
      currencyControl({
        key: "home_office_ownership_expenses",
        label: "Home-office ownership expenses",
        categories: [ "self_employed" ],
        hint: "Applied by business-use area percentage."
      }),
      {
        key: "home_office_business_use_percentage",
        type: "number",
        label: "Home-office business use",
        suffix: "%",
        min: 0,
        max: 100,
        step: "0.01",
        categories: [ "self_employed" ],
        defaultValue: "0",
        resultInputKey: "home_office_business_use_percentage"
      },
      currencyControl({
        key: "meals_expenses",
        label: "Deductible meals",
        categories: [ "self_employed" ],
        hint: "Separate meal/subsistence expense class."
      }),
      {
        key: "reta_contribution_mode",
        type: "select",
        label: "RETA contribution mode",
        categories: [ "self_employed" ],
        defaultValue: "standard",
        resultInputKey: "reta_contribution_mode",
        options: [
          { value: "standard", label: "Standard band contribution" },
          { value: "reduced_first_year", label: "80 EUR reduced quota: first year" },
          { value: "reduced_extension", label: "80 EUR reduced quota: extension" },
          { value: "reduced_special_24_months", label: "80 EUR special path" },
          { value: "reduced_special_following", label: "160 EUR special follow-up" }
        ]
      },
      {
        key: "family_collaborator",
        type: "checkbox",
        label: "Family collaborator reduction",
        categories: [ "self_employed" ],
        defaultValue: false,
        resultInputKey: "family_collaborator"
      },
      {
        key: "corporate_self_employed",
        type: "checkbox",
        label: "Corporate self-employed",
        categories: [ "self_employed" ],
        defaultValue: false,
        resultInputKey: "corporate_self_employed"
      },
      {
        key: "apply_reta_pluriactivity",
        type: "checkbox",
        label: "Estimate pluriactivity refund",
        categories: [ "self_employed" ],
        defaultValue: false,
        resultInputKey: "apply_reta_pluriactivity",
        children: [
          currencyControl({
            key: "employment_common_contingencies_paid",
            label: "Employee common-contingencies paid",
            categories: [ "self_employed" ],
            hint: "Used to estimate the RETA pluriactivity refund threshold.",
            visibleWhen: (controlValues) => Boolean(controlValues.apply_reta_pluriactivity)
          })
        ]
      }
    ],
    showAgeField: true,
    ageFieldHint: null,
    showChildrenCountField: true,
    showChildrenUnderThreeField: true,
    showDisabilityField: true,
    ageBracketOptions: [
      { value: "under_65", label: "Under 65" },
      { value: "from_65_to_74", label: "65 to 74" },
      { value: "age_75_plus", label: "75+" }
    ]
  }
};

export default spainCalculatorConfig;
