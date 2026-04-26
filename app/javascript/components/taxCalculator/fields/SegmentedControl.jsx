import React from "react";

export default function SegmentedControl({ hint = null, label, onChange, options, value }) {
  return (
    <div className="field">
      <span className="field-label">{label}</span>
      <div className="segmented-control">
        {options.map((option) => (
          <button
            key={option.value}
            className={option.value === value ? "is-active" : ""}
            type="button"
            onClick={() => onChange(option.value)}
          >
            {option.label}
          </button>
        ))}
      </div>
      {hint ? <span className="field-hint">{hint}</span> : null}
    </div>
  );
}
