require "rails_helper"

RSpec.describe Taxerase::RuleStatus do
  describe ".from_assumptions" do
    it "marks documented exclusions as needs_review statuses" do
      statuses = described_class.from_assumptions([
        "Regular employment income, standard deductions, and resident relief are included.",
        "No union dues, ascendants, joint filing, or other deductions and credits are included."
      ])

      expect(statuses).to contain_exactly(
        a_hash_including(
          status: "needs_review",
          status_label: "Needs review",
          severity: "review",
          label: "Documented rule needs review",
          message: "No union dues, ascendants, joint filing, or other deductions and credits are included."
        )
      )
    end
  end

  describe ".not_implemented" do
    it "builds a blocking status for unsupported documented rules" do
      expect(
        described_class.not_implemented(
          rule_key: "employee_navarre:2024:calculator_flow",
          label: "Resident employee - Navarre calculator flow",
          message: "Calculator flow is not implemented yet.",
          source_keys: [ "navarre_personal_income_tax" ]
        )
      ).to include(
        status: "not_implemented",
        status_label: "Not implemented",
        severity: "blocking",
        source_keys: [ "navarre_personal_income_tax" ]
      )
    end
  end
end
