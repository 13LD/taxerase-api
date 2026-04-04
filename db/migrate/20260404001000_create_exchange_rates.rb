class CreateExchangeRates < ActiveRecord::Migration[8.1]
  def change
    create_table :exchange_rates do |t|
      t.string :base_currency_code, null: false
      t.string :quote_currency_code, null: false
      t.date :rate_date, null: false
      t.decimal :rate_value, precision: 12, scale: 6, null: false
      t.string :provider, null: false
      t.string :source_name, null: false
      t.string :source_url, null: false
      t.datetime :fetched_at, null: false

      t.timestamps
    end

    add_index :exchange_rates, %i[provider base_currency_code quote_currency_code rate_date],
      unique: true,
      name: "idx_exchange_rates_provider_pair_date"
    add_index :exchange_rates, %i[provider base_currency_code rate_date],
      name: "idx_exchange_rates_provider_base_date"
  end
end
