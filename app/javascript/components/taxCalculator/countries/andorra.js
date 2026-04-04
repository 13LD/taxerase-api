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
        key: "ascendants_count",
        type: "select",
        label: "Dependent ascendants",
        hint: "Use this for dependent ascendants eligible for the Andorran family reduction.",
        categories: [ "employee", "self_employed" ],
        defaultValue: "0",
        resultInputKey: "ascendants_count",
        options: countOptions(3)
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
