import React from "react";
import {
  buildSanitizedValueEvent,
  sanitizeDecimalValue,
  sanitizeIntegerValue
} from "./sanitizeNumericValue";

export default function NumberField({
  hint = null,
  label,
  max = null,
  min = null,
  onChange,
  step = "1",
  suffix = null,
  value
}) {
  const allowsDecimals = step === "any" || String(step).includes(".");

  function handleChange(event) {
    const nextValue = allowsDecimals
      ? sanitizeDecimalValue(event.target.value)
      : sanitizeIntegerValue(event.target.value);

    onChange(buildSanitizedValueEvent(nextValue));
  }

  return (
    <label className="field">
      <span className="field-label">{label}</span>
      <div className={`number-input ${suffix ? "number-input--with-suffix" : ""}`.trim()}>
        <input
          type="text"
          autoComplete="off"
          inputMode={allowsDecimals ? "decimal" : "numeric"}
          pattern={allowsDecimals ? "[0-9]*[.,]?[0-9]*" : "[0-9]*"}
          spellCheck="false"
          data-min={min}
          data-max={max}
          data-step={step}
          value={value}
          onChange={handleChange}
        />
        {suffix ? <span className="number-input__suffix">{suffix}</span> : null}
      </div>
      {hint ? <span className="field-hint">{hint}</span> : null}
    </label>
  );
}
