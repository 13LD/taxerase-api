import React, { useId } from "react";
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
  const inputId = useId();
  const hintId = hint ? `${inputId}-hint` : undefined;
  const allowsDecimals = step === "any" || String(step).includes(".");

  function handleChange(event) {
    const nextValue = allowsDecimals
      ? sanitizeDecimalValue(event.target.value)
      : sanitizeIntegerValue(event.target.value);

    onChange(buildSanitizedValueEvent(nextValue));
  }

  return (
    <div className="field">
      <label className="field-label" htmlFor={inputId}>{label}</label>
      <div className={`number-input ${suffix ? "number-input--with-suffix" : ""}`.trim()}>
        <input
          aria-describedby={hintId}
          id={inputId}
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
      {hint ? <span className="field-hint" id={hintId}>{hint}</span> : null}
    </div>
  );
}
