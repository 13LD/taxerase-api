require "rails_helper"

RSpec.describe Taxerase::Poland::SpecialIncomeRelief do
  let(:regime) do
    TaxRegime.find_by!(
      country: Country.find_by!(code: "PL"),
      key: "employee_poland",
      tax_year: 2025
    )
  end

  describe ".call" do
    it "applies the shared exemption cap once even when multiple special reliefs are enabled" do
      result = described_class.call(
        regime:,
        age_bracket: "retirement_age_or_older",
        apply_return_relief: true,
        apply_family_4plus_relief: true,
        apply_working_senior_relief: true
      )

      expect(result[:enabled_reliefs]).to contain_exactly(
        "Return relief",
        "Family 4+ relief",
        "Working senior relief"
      )
      expect(result[:exempt_income_cap]).to eq(BigDecimal("85528"))
    end
  end

  describe ".validation_errors_for" do
    it "requires at least 4 children for family 4+ relief" do
      expect(
        described_class.validation_errors_for(
          age_bracket: "age_26_to_retirement",
          children_count: 3,
          apply_family_4plus_relief: true,
          apply_working_senior_relief: false
        )
      ).to include("family 4+ relief requires at least 4 children")
    end

    it "requires retirement age for working senior relief" do
      expect(
        described_class.validation_errors_for(
          age_bracket: "age_26_to_retirement",
          children_count: 4,
          apply_family_4plus_relief: false,
          apply_working_senior_relief: true
        )
      ).to include("working senior relief requires retirement age or older")
    end
  end
end
