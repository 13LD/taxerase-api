import React from "react";
import TaxComparisonCard from "./taxCalculator/TaxComparisonCard";
import useTaxComparisonEngine from "./taxCalculator/useTaxComparisonEngine";

export default function ComparisonTab({ calculatorProps }) {
  const { comparison_catalog: comparisonCatalog, country, default_input: defaultInput } = calculatorProps;
  const { comparisonProps } = useTaxComparisonEngine({
    comparisonCatalog: comparisonCatalog || [],
    currentCountryCode: country?.code || "",
    defaultGrossIncome: defaultInput?.gross_income
  });

  return (
    <section className="comparison-tab">
      <div className="glass-stack">
        <TaxComparisonCard {...comparisonProps} />
      </div>
    </section>
  );
}
