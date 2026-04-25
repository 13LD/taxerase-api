require "rails_helper"

RSpec.describe Taxerase::Compliance::ReportCalendar do
  describe ".call" do
    it "serializes Spain report workflows and deadline events in calendar order" do
      payload = described_class.call(country_code: "ES", tax_year: 2026)
      modelo_130 = payload.fetch(:reports).find { |report| report.fetch(:key) == "modelo_130" }

      expect(payload.dig(:country, :code)).to eq("ES")
      expect(modelo_130.fetch(:workflows).first.fetch(:name)).to eq("Quarterly IRPF payment workflow")
      expect(modelo_130.fetch(:events).first).to include(
        event_type: "submission",
        event_date: "2026-04-20",
        window_start_date: "2026-04-01",
        window_end_date: "2026-04-20"
      )
      expect(modelo_130.fetch(:events).map { |event| event.fetch(:event_date) }).to eq(
        modelo_130.fetch(:events).map { |event| event.fetch(:event_date) }.sort
      )
    end
  end
end
