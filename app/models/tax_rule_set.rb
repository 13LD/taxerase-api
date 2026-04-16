class TaxRuleSet < ApplicationRecord
  belongs_to :country
  has_many :tax_regimes, dependent: :destroy

  validates :key, presence: true, uniqueness: { scope: %i[country_id tax_year] }
  validates :name, presence: true
  validates :tax_year, presence: true
  validates :release_version, presence: true
  validates :status, presence: true
end
