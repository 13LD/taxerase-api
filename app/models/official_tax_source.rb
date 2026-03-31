class OfficialTaxSource < ApplicationRecord
  has_many :tax_source_usages, dependent: :destroy
  has_many :tax_regimes, through: :tax_source_usages

  validates :key, presence: true, uniqueness: true
  validates :title, presence: true
  validates :authority_name, presence: true
  validates :country_code, presence: true
  validates :jurisdiction, presence: true
  validates :source_type, presence: true
  validates :url, presence: true
end
