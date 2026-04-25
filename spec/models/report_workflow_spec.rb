require "rails_helper"

RSpec.describe ReportWorkflow, type: :model do
  it "accepts full HTTP and HTTPS reference URLs only" do
    report = TaxReport.find_by!(key: "modelo_130", tax_year: 2026)
    workflow = report.report_workflows.build(
      key: "reference_validation",
      name: "Reference validation",
      description: "Validates official references.",
      position: 99
    )

    workflow.reference_url = "https://sede.agenciatributaria.gob.es/Sede/procedimientoini/G601.shtml"
    expect(workflow).to be_valid

    [
      "data:text/html,https://example.com",
      "javascript:alert(1)//https://example.com",
      "ftp://example.com",
      "https://"
    ].each do |reference_url|
      workflow.reference_url = reference_url

      expect(workflow).not_to be_valid
      expect(workflow.errors[:reference_url]).to include("must be a valid HTTP or HTTPS URL")
    end
  end
end
