require "rails_helper"

RSpec.describe Taxerase::ExchangeRates::FrankfurterClient do
  subject(:client) { described_class.new }

  let(:response) { instance_double(Net::HTTPSuccess, body: body) }

  before do
    allow(Net::HTTP).to receive(:get_response).and_return(response)
    allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
  end

  describe "#fetch_latest" do
    context "when Frankfurter returns an array payload" do
      let(:body) do
        [
          { base: "EUR", quote: "PLN", date: "2026-04-03", rate: 4.25 },
          { base: "EUR", quote: "CZK", date: "2026-04-03", rate: 24.38 }
        ].to_json
      end

      it "normalizes the exchange-rate rows" do
        rows = client.fetch_latest(
          base_currency_code: "EUR",
          quote_currency_codes: %w[PLN CZK]
        )

        expect(rows).to contain_exactly(
          include(
            base_currency_code: "EUR",
            quote_currency_code: "PLN",
            rate_date: Date.new(2026, 4, 3),
            rate_value: BigDecimal("4.25")
          ),
          include(
            base_currency_code: "EUR",
            quote_currency_code: "CZK",
            rate_date: Date.new(2026, 4, 3),
            rate_value: BigDecimal("24.38")
          )
        )
      end
    end

    context "when Frankfurter returns a hash payload with rates" do
      let(:body) do
        {
          base: "EUR",
          date: "2026-04-03",
          rates: {
            "PLN" => 4.25,
            "CZK" => 24.38
          }
        }.to_json
      end

      it "normalizes the exchange-rate rows" do
        rows = client.fetch_latest(
          base_currency_code: "EUR",
          quote_currency_codes: %w[PLN CZK]
        )

        expect(rows.map { |row| row[:quote_currency_code] }).to contain_exactly("PLN", "CZK")
        expect(rows.map { |row| row[:rate_date] }.uniq).to eq([ Date.new(2026, 4, 3) ])
      end
    end
  end
end
