require "rails_helper"

RSpec.describe Taxerase::Seeds::ComplianceReports do
  describe "#replace_workflows!" do
    it "raises when a workflow reference_url is not an HTTP(S) URL" do
      country = Country.create!(code: "ZZ", name: "Testland", currency_code: "EUR")
      report = TaxReport.create!(
        country:,
        tax_year: 2026,
        key: "test_report",
        name: "Test report",
        active: true
      )

      workflows = [
        {
          "key" => "submit_test_report",
          "name" => "Submit test report",
          "description" => "Submit the test report",
          "reference_url" => "javascript:alert(1)"
        }
      ]

      expect do
        described_class.new.send(:replace_workflows!, report, workflows)
      end.to raise_error(
        ArgumentError,
        /Invalid reference_url for report test_report workflow submit_test_report/
      )
    end
  end
end
