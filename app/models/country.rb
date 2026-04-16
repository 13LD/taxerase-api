class Country < ApplicationRecord
  has_many :tax_rule_sets, dependent: :destroy
  has_many :tax_regimes, through: :tax_rule_sets
  has_many :official_tax_sources, dependent: :destroy

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :currency_code, presence: true
end
