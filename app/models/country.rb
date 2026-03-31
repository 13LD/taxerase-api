class Country < ApplicationRecord
  has_many :tax_regimes, dependent: :destroy

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :currency_code, presence: true
end
