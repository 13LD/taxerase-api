import React from "react";

export default function SelectField({ disabled = false, hint = null, label, onChange, options, value }) {
  return (
    <label className="field">
      <span className="field-label">{label}</span>
      <div className="select-shell">
        <select disabled={disabled} value={value} onChange={onChange}>
          {options.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
      </div>
      {hint ? <span className="field-hint">{hint}</span> : null}
    </label>
  );
}
