import React from "react";
import { currencySymbol } from "../formatters";
import { buildSanitizedValueEvent, sanitizeDecimalValue } from "./sanitizeNumericValue";

export default function CurrencyField({ currencyCode = "EUR", hint = null, label, onChange, value }) {
  function handleChange(event) {
    onChange(buildSanitizedValueEvent(sanitizeDecimalValue(event.target.value)));
  }

  return (
    <label className="field">
      <span className="field-label">{label}</span>
      <div className="currency-input">
        <span className="currency-input__symbol">{currencySymbol(currencyCode)}</span>
        <input
          type="text"
          autoComplete="off"
          inputMode="decimal"
          pattern="[0-9]*[.,]?[0-9]*"
          spellCheck="false"
          value={value}
          onChange={handleChange}
        />
      </div>
      {hint ? <span className="field-hint">{hint}</span> : null}
    </label>
  );
}
