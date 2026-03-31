import React from "react";
import { createRoot } from "react-dom/client";
import SpainCalculatorApp from "./components/SpainCalculatorApp";

document.addEventListener("DOMContentLoaded", () => {
  const container = document.getElementById("spain-calculator-app");
  if (!container) return;

  const props = JSON.parse(container.dataset.props || "{}");
  createRoot(container).render(<SpainCalculatorApp {...props} />);
});
