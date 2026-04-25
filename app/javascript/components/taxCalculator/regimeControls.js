function flattenControls(regimeControls) {
  return regimeControls.flatMap((control) => [
    control,
    ...flattenControls(control.children || [])
  ]);
}

function defaultValueForControl(control) {
  if (control.type === "checkbox") return false;
  if (control.type === "select") return control.options?.[0]?.value || "";

  return "";
}

function isControlVisible(control, selectedCategory, controlValues, selectedTaxYear) {
  if (control.categories && !control.categories.includes(selectedCategory)) return false;
  if (control.visibleWhen && !control.visibleWhen(controlValues, selectedCategory, selectedTaxYear)) return false;

  return true;
}

function isControlActive(control, controlValues) {
  if (control.activeWhen) return control.activeWhen(controlValues[control.key], controlValues);
  if (control.type === "checkbox") return Boolean(controlValues[control.key]);

  return false;
}

function normalizeNumericSignatureValue(value) {
  if (value === null || value === undefined) return 0;

  const rawValue = String(value).trim();
  if (rawValue === "") return 0;

  const numericValue = Number(rawValue);
  return Number.isFinite(numericValue) ? numericValue : value;
}

function serializeSignatureValue(value, control) {
  if (value === true) return "1";
  if (value === false) return "0";

  if (control.type === "currency" || control.type === "number") {
    return String(normalizeNumericSignatureValue(value) ?? "");
  }

  return value == null ? "" : String(value);
}

function normalizePayloadValue(value, control) {
  if (control.type !== "currency" && control.type !== "number") return value;

  return normalizeNumericSignatureValue(value);
}

export function buildInitialRegimeControlValues({ defaultInput, regimeControls }) {
  return flattenControls(regimeControls).reduce((values, control) => {
    values[control.key] = defaultInput[control.key] ?? control.defaultValue ?? defaultValueForControl(control);
    return values;
  }, {});
}

export function buildVisibleRegimeControls({
  regimeControls,
  selectedCategory,
  controlValues,
  selectedTaxYear
}) {
  return regimeControls.flatMap((control) => {
    if (!isControlVisible(control, selectedCategory, controlValues, selectedTaxYear)) return [];

    return [
      control,
      ...buildVisibleRegimeControls({
        regimeControls: control.children || [],
        selectedCategory,
        controlValues,
        selectedTaxYear
      })
    ];
  });
}

export function resolveRegimeControlEffects({
  regimeControls,
  selectedCategory,
  controlValues,
  selectedTaxYear
}) {
  return buildVisibleRegimeControls({
    regimeControls,
    selectedCategory,
    controlValues,
    selectedTaxYear
  }).reduce((effects, control) => {
    if (!isControlActive(control, controlValues) || !control.effects) return effects;

    return {
      ...effects,
      ...control.effects
    };
  }, {});
}

export function buildRegimeControlPayload({
  regimeControls,
  selectedCategory,
  controlValues,
  selectedTaxYear
}) {
  return buildVisibleRegimeControls({
    regimeControls,
    selectedCategory,
    controlValues,
    selectedTaxYear
  }).reduce((payload, control) => {
    payload[control.key] = normalizePayloadValue(controlValues[control.key], control);
    return payload;
  }, {});
}

export function buildSelectedControlSignatureParts({
  regimeControls,
  selectedCategory,
  controlValues,
  selectedTaxYear
}) {
  return buildVisibleRegimeControls({
    regimeControls,
    selectedCategory,
    controlValues,
    selectedTaxYear
  })
    .filter((control) => Boolean(control.resultInputKey))
    .map((control) => serializeSignatureValue(controlValues[control.key], control));
}

export function buildResultControlSignatureParts({
  result,
  regimeControls,
  selectedCategory,
  controlValues,
  selectedTaxYear
}) {
  return buildVisibleRegimeControls({
    regimeControls,
    selectedCategory,
    controlValues,
    selectedTaxYear
  })
    .filter((control) => Boolean(control.resultInputKey))
    .map((control) => serializeSignatureValue(result?.input?.[control.resultInputKey], control));
}
