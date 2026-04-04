require "rails_helper"

RSpec.describe ExchangeRate do
  it "returns the latest stored rate for a provider pair" do
    provider = "TEST"

    older = ExchangeRate.create!(
      base_currency_code: "EUR",
      quote_currency_code: "PLN",
      rate_date: Date.new(2026, 3, 11),
      rate_value: BigDecimal("4.2523"),
      provider: provider,
      source_name: "Frankfurter exchange rates API",
      source_url: "https://api.frankfurter.dev/v2/rates?base=EUR&quotes=PLN,CZK",
      fetched_at: Time.zone.parse("2026-03-11 00:00:00 UTC")
    )

    newer = ExchangeRate.create!(
      base_currency_code: "EUR",
      quote_currency_code: "PLN",
      rate_date: Date.new(2026, 4, 3),
      rate_value: BigDecimal("4.3000"),
      provider: provider,
      source_name: "Frankfurter exchange rates API",
      source_url: "https://api.frankfurter.dev/v2/rates?base=EUR&quotes=PLN,CZK",
      fetched_at: Time.zone.parse("2026-04-03 00:00:00 UTC")
    )

    expect(described_class.latest_rate_date_for!(provider: provider, base_currency_code: "EUR")).to eq(Date.new(2026, 4, 3))
    expect(described_class.latest_for!(provider: provider, base_currency_code: "EUR", quote_currency_code: "PLN")).to eq(newer)
    expect(older).not_to eq(newer)
  end
end
