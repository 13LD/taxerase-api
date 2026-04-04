class ExchangeRatesSyncJob
  @queue = :exchange_rates

  def self.perform
    Taxerase::ExchangeRates::SyncRates.call
  end
end
