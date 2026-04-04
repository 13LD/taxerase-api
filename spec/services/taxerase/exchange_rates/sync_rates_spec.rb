require "rails_helper"

RSpec.describe Taxerase::ExchangeRates::SyncRates do
  include ActiveSupport::Testing::TimeHelpers

  let(:rows) do
    [
      {
        base_currency_code: "EUR",
        quote_currency_code: "PLN",
        rate_date: Date.new(2026, 4, 3),
        rate_value: BigDecimal("4.2500"),
        source_url: "https://api.frankfurter.dev/v2/rates?base=EUR&quotes=GBP,CHF,NOK,SEK,DKK,PLN,CZK,HUF,RON,ISK"
      },
      {
        base_currency_code: "EUR",
        quote_currency_code: "CZK",
        rate_date: Date.new(2026, 4, 3),
        rate_value: BigDecimal("24.3800"),
        source_url: "https://api.frankfurter.dev/v2/rates?base=EUR&quotes=GBP,CHF,NOK,SEK,DKK,PLN,CZK,HUF,RON,ISK"
      }
    ]
  end

  let(:client) do
    instance_double(Taxerase::ExchangeRates::FrankfurterClient).tap do |double|
      allow(double).to receive(:fetch_latest).and_return(rows)
    end
  end

  it "upserts fetched rates into the database" do
    freeze_time do
      expect {
        described_class.call(client: client)
      }.to change(ExchangeRate, :count).by(2)

      expect(ExchangeRate.latest_for!(provider: "FRANKFURTER", base_currency_code: "EUR", quote_currency_code: "PLN", rate_date: Date.new(2026, 4, 3)).rate_value.to_d)
        .to eq(BigDecimal("4.25"))
    end
  end

  it "updates an existing rate row when the same pair and date are fetched again" do
    described_class.call(client: client, fetched_at: Time.zone.parse("2026-04-03 10:00:00 UTC"))

    updated_rows = rows.map do |row|
      row.merge(rate_value: row.fetch(:quote_currency_code) == "PLN" ? BigDecimal("4.3000") : row[:rate_value])
    end
    updated_client = instance_double(Taxerase::ExchangeRates::FrankfurterClient).tap do |double|
      allow(double).to receive(:fetch_latest).and_return(updated_rows)
    end

    expect {
      described_class.call(client: updated_client, fetched_at: Time.zone.parse("2026-04-03 12:00:00 UTC"))
    }.not_to change(ExchangeRate, :count)

    expect(ExchangeRate.latest_for!(provider: "FRANKFURTER", base_currency_code: "EUR", quote_currency_code: "PLN", rate_date: Date.new(2026, 4, 3)).rate_value.to_d)
      .to eq(BigDecimal("4.3"))
  end
end
