class TaxReport < ApplicationRecord
  belongs_to :country
  has_many :report_workflows, dependent: :destroy
  has_many :report_events, dependent: :destroy

  validates :key, presence: true, uniqueness: { scope: %i[country_id tax_year] }
  validates :name, presence: true
  validates :tax_year, presence: true

  scope :for_country_year, ->(country:, tax_year:) {
    where(country:, tax_year:)
  }

  scope :active, -> { where(active: true) }
  scope :ordered_for_calendar, -> { order(:tax_year, :name) }
end
