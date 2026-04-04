class ExchangeRate < ApplicationRecord
  validates :base_currency_code, presence: true
  validates :quote_currency_code, presence: true
  validates :rate_date, presence: true
  validates :rate_value, presence: true, numericality: { greater_than: 0 }
  validates :provider, presence: true
  validates :source_name, presence: true
  validates :source_url, presence: true
  validates :fetched_at, presence: true
  validates :quote_currency_code, uniqueness: { scope: %i[provider base_currency_code rate_date] }

  scope :for_provider, ->(provider) { where(provider: provider.to_s.upcase) }
  scope :for_base, ->(base_currency_code) { where(base_currency_code: base_currency_code.to_s.upcase) }
  scope :for_quote, ->(quote_currency_code) { where(quote_currency_code: quote_currency_code.to_s.upcase) }
  scope :on_date, ->(rate_date) { where(rate_date: rate_date) }

  before_validation do
    self.base_currency_code = base_currency_code.to_s.upcase
    self.quote_currency_code = quote_currency_code.to_s.upcase
    self.provider = provider.to_s.upcase
  end

  def self.latest_rate_date_for!(provider:, base_currency_code:)
    for_provider(provider).for_base(base_currency_code).maximum(:rate_date) ||
      raise(KeyError, "No stored exchange rates are available for #{provider.inspect} #{base_currency_code.inspect}.")
  end

  def self.latest_for!(provider:, base_currency_code:, quote_currency_code:, rate_date: nil)
    effective_date = rate_date || latest_rate_date_for!(provider:, base_currency_code:)
    for_provider(provider)
      .for_base(base_currency_code)
      .for_quote(quote_currency_code)
      .on_date(effective_date)
      .first || raise(KeyError, "No stored exchange rate is available for #{base_currency_code.inspect}/#{quote_currency_code.inspect} on #{effective_date}.")
  end

  def self.latest_snapshot_for!(provider:, base_currency_code:)
    effective_date = latest_rate_date_for!(provider:, base_currency_code:)
    for_provider(provider).for_base(base_currency_code).on_date(effective_date).order(:quote_currency_code)
  end
end
