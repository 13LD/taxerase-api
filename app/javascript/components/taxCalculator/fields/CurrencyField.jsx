import React from "react";

export default function CurrencyField({ label, onChange, value }) {
  return (
    <label className="field">
      <span className="field-label">{label}</span>
      <div className="currency-input">
        <span>€</span>
        <input
          type="number"
          min="0"
          step="0.01"
          inputMode="decimal"
          value={value}
          onChange={onChange}
        />
      </div>
    </label>
  );
}
