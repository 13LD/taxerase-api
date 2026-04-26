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
        hint:
          "Parents or grandparents who qualify for Spain's ascendant minimum. This increases the personal and family minimum before tax is calculated.",
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
        hint:
          "Subset of dependent ascendants aged over 75. Spain adds an extra ascendant minimum for this age band.",
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
        hint:
          "Dependent ascendants with recognized disability from 33% to 64%; used for the ascendant disability minimum.",
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
        hint:
          "Dependent ascendants with recognized disability of 65% or more; this applies the higher ascendant disability minimum.",
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
        hint:
          "Disabled dependent ascendants with reduced mobility or third-party support needs; adds the support increment.",
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
        hint:
          "Applies the Spanish family-unit reduction for married or single-parent joint filing instead of individual filing.",
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
        hint:
          "Union membership fees paid by an employee. The calculator subtracts them as deductible work-income expenses."
      }),
      currencyControl({
        key: "professional_fees",
        label: "Compulsory professional fees",
        categories: [ "employee" ],
        hint:
          "Mandatory professional association fees required for the job. The calculator applies the statutory deductible cap."
      }),
      currencyControl({
        key: "legal_defense_costs",
        label: "Labor legal-defense costs",
        categories: [ "employee" ],
        hint:
          "Legal defense costs from employment disputes. The calculator applies the employment legal-defense cap."
      }),
      {
        key: "disabled_worker_status",
        type: "select",
        label: "Disabled worker expense",
        hint:
          "Adds Spain's increased deductible employment expense for workers with recognized disability, with a higher amount for 65%+ or support needs.",
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
        hint:
          "Use when unemployment-to-employment relocation rules apply. This adds the Spanish geographic-mobility work-expense increase.",
        categories: [ "employee" ],
        defaultValue: false,
        resultInputKey: "geographic_mobility",
        visibleWhen: visibleUnlessEmployeeBeckham
      },
      {
        key: "large_family_category",
        type: "select",
        label: "Large-family deduction",
        hint:
          "Select the official large-family category. The calculator applies the national family deduction for general or special category families.",
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
        hint:
          "Children above the baseline large-family threshold. Spain adds an extra deduction amount for each additional child.",
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
        hint:
          "Use for the national deduction for a single parent with two children when the statutory conditions are met.",
        categories: [ "employee", "self_employed" ],
        defaultValue: false,
        resultInputKey: "single_parent_two_children",
        visibleWhen: visibleUnlessEmployeeBeckham
      },
      {
        key: "maternity_eligible_months",
        type: "select",
        label: "Maternity deduction months",
        hint:
          "Months eligible for Spain's maternity deduction. The calculator multiplies the monthly deduction by this count.",
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
        hint:
          "Eligible nursery or childcare centre costs. The calculator applies the additional maternity increment up to the annual cap."
      }),
      {
        key: "disabled_descendants_count",
        type: "select",
        label: "Disabled descendants in charge",
        hint:
          "Children or descendants in your care with recognized disability. The calculator applies the national disability-in-care deduction.",
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
        hint:
          "Parents or grandparents in your care with recognized disability. The calculator applies the national disability-in-care deduction.",
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
        hint:
          "Use when the spouse qualifies as a dependent with disability for Spain's national family deduction.",
        categories: [ "employee", "self_employed" ],
        defaultValue: false,
        resultInputKey: "spouse_disability_dependant",
        visibleWhen: visibleUnlessEmployeeBeckham
      },
      {
        key: "self_employed_estimation_method",
        type: "select",
        label: "Self-employed estimation method",
        hint:
          "Direct simplified and direct normal use actual expense inputs; modules use the seeded objective-estimation net-income rate.",
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
        hint:
          "Utilities and supply costs for a declared home workspace. Spain applies 30% of the business-use area share."
      }),
      currencyControl({
        key: "home_office_ownership_expenses",
        label: "Home-office ownership expenses",
        categories: [ "self_employed" ],
        hint:
          "Ownership or occupancy costs for the business-use part of the home. The calculator applies the entered business-use percentage."
      }),
      {
        key: "home_office_business_use_percentage",
        type: "number",
        label: "Home-office business use",
        hint:
          "Percentage of the home allocated to business use. This drives the home-office supply and ownership deductions.",
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
        hint:
          "Eligible business meal and subsistence costs entered separately from ordinary expenses for direct-estimation calculations."
      }),
      {
        key: "reta_contribution_mode",
        type: "select",
        label: "RETA contribution mode",
        hint:
          "RETA is Spain's self-employed social-security regime. Select standard contribution or one of the reduced-quota paths.",
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
        hint:
          "Use when the self-employed worker qualifies for the family-collaborator Social Security reduction.",
        categories: [ "self_employed" ],
        defaultValue: false,
        resultInputKey: "family_collaborator"
      },
      {
        key: "corporate_self_employed",
        type: "checkbox",
        label: "Corporate self-employed",
        hint:
          "Use for autónomo societario cases. The calculator applies the corporate self-employed contribution-base handling.",
        categories: [ "self_employed" ],
        defaultValue: false,
        resultInputKey: "corporate_self_employed"
      },
      {
        key: "apply_reta_pluriactivity",
        type: "checkbox",
        label: "Estimate pluriactivity refund",
        hint:
          "Use when the person paid both employee common-contingencies contributions and RETA. The calculator estimates the refund threshold.",
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
    ageFieldHint:
      "Applies Spain's taxpayer age increments to the personal and family minimum for age 65+ and 75+.",
    showChildrenCountField: true,
    childrenCountHint:
      "Counts descendants for Spain's descendant minimum and family deductions. Amounts increase by child order.",
    showChildrenUnderThreeField: true,
    childrenUnderThreeHint:
      "Subset of declared children under 3. Spain adds an extra descendant minimum for each child in this age band.",
    showDisabilityField: true,
    disabilityFieldHint:
      "Applies Spain's taxpayer disability minimum, with higher relief for 65%+ disability or support needs.",
    ageBracketOptions: [
      { value: "under_65", label: "Under 65" },
      { value: "from_65_to_74", label: "65 to 74" },
      { value: "age_75_plus", label: "75+" }
    ]
  }
};

export default spainCalculatorConfig;
