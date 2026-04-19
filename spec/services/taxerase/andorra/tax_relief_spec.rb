require "rails_helper"

RSpec.describe Taxerase::Andorra::TaxRelief do
  def parameter_decimal(key)
    {
      "personal_reduction_default" => BigDecimal("24000"),
      "personal_reduction_disability" => BigDecimal("30000"),
      "personal_reduction_spouse_without_income" => BigDecimal("40000"),
      "dependent_reduction" => BigDecimal("750"),
      "family_member_disability_extra" => BigDecimal("375"),
      "mortgage_interest_credit_rate" => BigDecimal("0.25"),
      "mortgage_interest_credit_cap" => BigDecimal("1000"),
      "pension_contribution_reduction_cap" => BigDecimal("5000"),
      "pension_contribution_income_rate_cap" => BigDecimal("0.30")
    }.fetch(key)
  end

  describe ".reductions" do
    it "applies the spouse-income phase-in from the official example" do
      reductions = described_class.reductions(
        children_count: 0,
        disability_level: "none",
        has_spouse_or_partner: true,
        spouse_without_income: false,
        spouse_general_income: 10_980,
        disabled_dependents_count: 0,
        mortgage_interest: 0,
        pension_contributions: 0,
        alimony_paid: 0,
        net_general_income: BigDecimal("50325"),
        parameter_decimal: method(:parameter_decimal)
      )

      expect(reductions[:spouse_phase_in_increment]).to eq(BigDecimal("5020"))
      expect(reductions[:taxpayer_reduction]).to eq(BigDecimal("29020"))
    end

    it "adds the dependent disability uplift separately from the base dependent reduction" do
      reductions = described_class.reductions(
        children_count: 3,
        disability_level: "none",
        has_spouse_or_partner: false,
        spouse_without_income: false,
        spouse_general_income: 0,
        disabled_dependents_count: 2,
        mortgage_interest: 0,
        pension_contributions: 0,
        alimony_paid: 0,
        net_general_income: BigDecimal("40000"),
        parameter_decimal: method(:parameter_decimal)
      )

      expect(reductions[:dependent_reduction]).to eq(BigDecimal("2250"))
      expect(reductions[:dependent_disability_uplift]).to eq(BigDecimal("750"))
      expect(reductions[:total_base_reductions]).to eq(BigDecimal("27000"))
    end
  end
end
