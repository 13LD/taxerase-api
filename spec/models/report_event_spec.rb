require "rails_helper"

RSpec.describe ReportEvent, type: :model do
  it "requires submission events to carry a submission window ending on the deadline" do
    report = TaxReport.find_by!(key: "modelo_130", tax_year: 2026)
    event = report.report_events.build(
      key: "missing_window",
      title: "Missing submission window",
      event_type: "submission",
      event_date: Date.new(2026, 4, 20),
      position: 99
    )

    expect(event).not_to be_valid
    expect(event.errors[:window_start_date]).to include("is required for submission events")
    expect(event.errors[:window_end_date]).to include("is required for submission events")

    event.window_start_date = Date.new(2026, 4, 1)
    event.window_end_date = Date.new(2026, 4, 19)

    expect(event).not_to be_valid
    expect(event.errors[:event_date]).to include("must match the submission window end date")
  end
end
