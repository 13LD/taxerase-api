require "rails_helper"

RSpec.describe Taxerase::CzechRepublic::PersonalReliefs do
  let(:regime) do
    TaxRegime
      .for_country_year(country: Country.find_by!(code: "CZ"), tax_year: 2025)
      .find_by!(key: "employee_czech_republic")
  end

  it "allows donations exactly at the tax-base percentage threshold" do
    reliefs = described_class.new(
      regime:,
      child_credit_claim_share: 100,
      apply_spouse_credit: false,
      spouse_income: 0,
      spouse_ztp_p: false,
      spouse_cares_child_under_three: false,
      mortgage_interest_paid: 0,
      pension_contributions: 0,
      life_insurance_contributions: 0,
      donations_amount: 800
    )

    expect(reliefs.non_taxable_deductions_for(BigDecimal("40000"))).to eq(BigDecimal("800"))
  end
end
