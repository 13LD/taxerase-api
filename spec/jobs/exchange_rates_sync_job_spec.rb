require "rails_helper"

RSpec.describe ExchangeRatesSyncJob do
  it "delegates to the sync service" do
    allow(Taxerase::ExchangeRates::SyncRates).to receive(:call)

    described_class.perform

    expect(Taxerase::ExchangeRates::SyncRates).to have_received(:call)
  end
end
