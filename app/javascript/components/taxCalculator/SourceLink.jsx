import React from "react";

export default function SourceLink({ source }) {
  return (
    <a className="source-link" href={source.href} target="_blank" rel="noreferrer">
      <span>{source.label}</span>
      <span aria-hidden="true">↗</span>
    </a>
  );
}
