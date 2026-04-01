import React from "react";

export default function CheckboxField({ checked, hint = null, label, onChange }) {
  return (
    <div className="field">
      <label className="checkbox-shell">
        <input checked={checked} onChange={onChange} type="checkbox" />
        <span>{label}</span>
      </label>
      {hint ? <span className="field-hint">{hint}</span> : null}
    </div>
  );
}
