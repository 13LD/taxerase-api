namespace :taxerase do
  namespace :exchange_rates do
    desc "Fetch and persist the latest EUR-based exchange rates from Frankfurter"
    task sync: :environment do
      Taxerase::ExchangeRates::SyncRates.call
      puts "exchange-rates-sync-ok"
    end
  end
end
