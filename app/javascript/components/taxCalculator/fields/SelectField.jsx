import React, { useId } from "react";

export default function SelectField({ disabled = false, hint = null, label, onChange, options, value }) {
  const selectId = useId();
  const hintId = hint ? `${selectId}-hint` : undefined;

  return (
    <div className="field">
      <label className="field-label" htmlFor={selectId}>{label}</label>
      <div className="select-shell">
        <select
          aria-describedby={hintId}
          disabled={disabled}
          id={selectId}
          value={value}
          onChange={onChange}
        >
          {options.map((option) => (
            <option key={option.value} value={option.value}>
              {option.label}
            </option>
          ))}
        </select>
      </div>
      {hint ? <span className="field-hint" id={hintId}>{hint}</span> : null}
    </div>
  );
}
