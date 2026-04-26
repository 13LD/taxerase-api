require "rails_helper"

RSpec.describe Taxerase::Compliance::ReportCalendar do
  describe ".call" do
    it "serializes Spain report workflows and deadline events in calendar order" do
      payload = described_class.call(country_code: "ES", tax_year: 2026)
      reports = expect_multi_year_payload(payload, country_code: "ES")
      modelo_130 = report_by_key_and_year(reports, "modelo_130", 2026)

      expect(report_by_key_and_year(reports, "modelo_130", 2025).fetch(:events).first).to include(
        event_type: "submission",
        event_date: "2025-04-20",
        window_start_date: "2025-04-01",
        window_end_date: "2025-04-20"
      )
      expect(report_by_key_and_year(reports, "modelo_100", 2027).fetch(:events)).to include(
        hash_including(
          event_type: "submission",
          event_date: "2027-06-30",
          window_start_date: "2027-04-08",
          window_end_date: "2027-06-30"
        )
      )
      expect(report_by_key_and_year(reports, "modelo_303", 2027).fetch(:events)).to include(
        hash_including(event_type: "payment", event_date: "2028-01-30")
      )
      expect(modelo_130.fetch(:workflows).map { |workflow| workflow.fetch(:name) }).to eq(
        [
          "Prepare quarterly IRPF inputs",
          "Submit Modelo 130",
          "Settle the quarterly IRPF payment"
        ]
      )
      expect(modelo_130.fetch(:workflows).first.fetch(:reference_url)).to eq(
        "https://sede.agenciatributaria.gob.es/Sede/procedimientoini/G601.shtml"
      )
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

    it "serializes Netherlands compliance reports across the same multi-year window" do
      payload = described_class.call(country_code: "NL", tax_year: 2026)
      reports = expect_multi_year_payload(payload, country_code: "NL")
      btw_aangifte = report_by_key_and_year(reports, "btw_aangifte_kwartaal", 2026)
      opgaaf_icp = report_by_key_and_year(reports, "opgaaf_icp", 2026)
      inkomstenbelasting = report_by_key_and_year(reports, "inkomstenbelasting", 2026)

      expect(report_by_key_and_year(reports, "btw_aangifte_kwartaal", 2027).fetch(:events)).to include(
        hash_including(event_type: "payment", event_date: "2028-01-31")
      )
      expect(btw_aangifte.fetch(:workflows).map { |workflow| workflow.fetch(:name) }).to eq(
        [
          "Reconcile quarterly BTW",
          "Submit BTW aangifte",
          "Pay quarterly BTW"
        ]
      )
      expect(btw_aangifte.fetch(:workflows).first.fetch(:reference_url)).to eq(
        "https://www.belastingdienst.nl/wps/wcm/connect/nl/btw/content/uiterste-aangifte-en-betaaldatums"
      )
      expect(btw_aangifte.fetch(:events).first).to include(
        event_type: "submission",
        event_date: "2026-04-30",
        window_start_date: "2026-04-01",
        window_end_date: "2026-04-30"
      )
      expect(opgaaf_icp.fetch(:events)).to include(
        hash_including(
          event_type: "submission",
          event_date: "2027-02-28",
          window_start_date: "2027-01-01",
          window_end_date: "2027-02-28"
        )
      )
      expect(inkomstenbelasting.fetch(:events)).to include(
        hash_including(
          event_type: "submission",
          event_date: "2027-05-01",
          window_start_date: "2027-03-01",
          window_end_date: "2027-05-01"
        )
      )
    end

    it "serializes Portugal compliance reports across the same multi-year window" do
      payload = described_class.call(country_code: "PT", tax_year: 2026)
      reports = expect_multi_year_payload(payload, country_code: "PT")
      modelo_3 = report_by_key_and_year(reports, "irs_modelo_3", 2026)
      quarterly_iva = report_by_key_and_year(reports, "iva_periodica_trimestral", 2026)
      monthly_iva = report_by_key_and_year(reports, "iva_periodica_mensal", 2026)
      invoice_communication = report_by_key_and_year(reports, "comunicacao_faturas", 2026)

      expect(reports.map { |report| report.fetch(:name) }).to include(
        "Declaracao Modelo 3",
        "IRS payments on account",
        "Quarterly IVA return",
        "Monthly IVA return",
        "Invoice communication"
      )
      expect(modelo_3.fetch(:events)).to include(
        hash_including(
          event_type: "submission",
          event_date: "2026-06-30",
          window_start_date: "2026-04-01",
          window_end_date: "2026-06-30"
        ),
        hash_including(event_type: "payment", event_date: "2026-08-31")
      )
      expect(quarterly_iva.fetch(:events)).to include(
        hash_including(
          event_type: "submission",
          event_date: "2027-02-20",
          window_start_date: "2027-02-01",
          window_end_date: "2027-02-20"
        ),
        hash_including(event_type: "payment", event_date: "2027-02-25")
      )
      expect(report_by_key_and_year(reports, "iva_periodica_trimestral", 2027).fetch(:events)).to include(
        hash_including(event_type: "payment", event_date: "2028-02-25")
      )
      expect(monthly_iva.fetch(:workflows).map { |workflow| workflow.fetch(:name) }).to include(
        "Confirm monthly IVA status",
        "Submit monthly IVA return",
        "Pay monthly IVA"
      )
      expect(invoice_communication.fetch(:events)).to include(
        hash_including(
          event_type: "submission",
          event_date: "2026-08-31",
          window_start_date: "2026-08-01",
          window_end_date: "2026-08-31"
        )
      )
    end

    it "serializes Poland compliance reports across the same multi-year window" do
      payload = described_class.call(country_code: "PL", tax_year: 2026)
      reports = expect_multi_year_payload(payload, country_code: "PL")
      pit_annual = report_by_key_and_year(reports, "pit_annual", 2026)
      jpk_v7m = report_by_key_and_year(reports, "jpk_v7_monthly", 2026)
      ksef_rollout = report_by_key_and_year(reports, "ksef_rollout", 2026)

      expect(reports.map { |report| report.fetch(:name) }).to include(
        "Annual PIT return",
        "Monthly JPK_V7M VAT return",
        "KSeF rollout"
      )
      expect(pit_annual.fetch(:events)).to include(
        hash_including(
          event_type: "submission",
          event_date: "2026-04-30",
          window_start_date: "2026-02-15",
          window_end_date: "2026-04-30"
        ),
        hash_including(event_type: "payment", event_date: "2026-04-30")
      )
      expect(jpk_v7m.fetch(:events)).to include(
        hash_including(event_type: "submission", event_date: "2026-12-28"),
        hash_including(event_type: "payment", event_date: "2027-01-25")
      )
      expect(ksef_rollout.fetch(:events)).to include(
        hash_including(event_type: "submission", event_date: "2026-02-01"),
        hash_including(event_type: "submission", event_date: "2026-04-01")
      )
    end

    it "serializes Czech Republic compliance reports across the same multi-year window" do
      payload = described_class.call(country_code: "CZ", tax_year: 2026)
      reports = expect_multi_year_payload(payload, country_code: "CZ")
      income_tax = report_by_key_and_year(reports, "personal_income_tax_return", 2026)
      vat_return = report_by_key_and_year(reports, "vat_return_monthly", 2026)
      control_statement = report_by_key_and_year(reports, "vat_control_statement_monthly", 2026)
      pausalni_dan = report_by_key_and_year(reports, "pausalni_dan_monthly", 2026)

      expect(reports.map { |report| report.fetch(:name) }).to include(
        "Personal income tax return",
        "Monthly VAT return",
        "Monthly VAT control statement",
        "Monthly pausalni dan advance"
      )
      expect(income_tax.fetch(:events)).to include(
        hash_including(event_type: "submission", event_date: "2026-04-01"),
        hash_including(event_type: "submission", event_date: "2026-05-04"),
        hash_including(event_type: "submission", event_date: "2026-07-01")
      )
      expect(vat_return.fetch(:events)).to include(
        hash_including(event_type: "submission", event_date: "2026-12-28"),
        hash_including(event_type: "payment", event_date: "2027-01-25")
      )
      expect(control_statement.fetch(:workflows).map { |workflow| workflow.fetch(:name) }).to include(
        "Validate control statement",
        "Submit control statement"
      )
      expect(pausalni_dan.fetch(:events)).to include(
        hash_including(event_type: "payment", event_date: "2026-01-20"),
        hash_including(event_type: "payment", event_date: "2026-12-21")
      )
    end
  end

  def expect_multi_year_payload(payload, country_code:)
    reports = payload.fetch(:reports)

    expect(payload.dig(:country, :code)).to eq(country_code)
    expect(payload.fetch(:tax_years)).to eq([ 2025, 2026, 2027 ])
    expect(payload.fetch(:start_year)).to eq(2025)
    expect(payload.fetch(:end_year)).to eq(2027)
    expect(reports.map { |report| report.fetch(:tax_year) }.uniq).to eq([ 2025, 2026, 2027 ])

    reports
  end

  def report_by_key_and_year(reports, key, tax_year)
    reports.find { |report| report.fetch(:key) == key && report.fetch(:tax_year) == tax_year }
  end
end
