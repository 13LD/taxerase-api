import React from "react";
import { createRoot } from "react-dom/client";
import CountryCalculatorApp from "./components/CountryCalculatorApp";

document.addEventListener("DOMContentLoaded", () => {
  const container = document.getElementById("country-calculator-app");
  if (!container) return;

  const props = JSON.parse(container.dataset.props || "{}");
  createRoot(container).render(<CountryCalculatorApp {...props} />);
});
