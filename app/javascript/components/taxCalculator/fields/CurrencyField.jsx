import React, { useId } from "react";
import { currencySymbol } from "../formatters";
import { buildSanitizedValueEvent, sanitizeDecimalValue } from "./sanitizeNumericValue";

export default function CurrencyField({ currencyCode = "EUR", hint = null, label, onChange, value }) {
  const inputId = useId();
  const hintId = hint ? `${inputId}-hint` : undefined;

  function handleChange(event) {
    onChange(buildSanitizedValueEvent(sanitizeDecimalValue(event.target.value)));
  }

  return (
    <div className="field">
      <label className="field-label" htmlFor={inputId}>{label}</label>
      <div className="currency-input">
        <span className="currency-input__symbol">{currencySymbol(currencyCode)}</span>
        <input
          aria-describedby={hintId}
          id={inputId}
          type="text"
          autoComplete="off"
          inputMode="decimal"
          pattern="[0-9]*[.,]?[0-9]*"
          spellCheck="false"
          value={value}
          onChange={handleChange}
        />
      </div>
      {hint ? <span className="field-hint" id={hintId}>{hint}</span> : null}
    </div>
  );
}
