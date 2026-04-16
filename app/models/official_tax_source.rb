class OfficialTaxSource < ApplicationRecord
  belongs_to :country
  has_many :tax_source_usages, dependent: :destroy
  has_many :tax_regimes, through: :tax_source_usages

  validates :key, presence: true, uniqueness: true
  validates :title, presence: true
  validates :authority_name, presence: true
  validates :country, presence: true
  validates :jurisdiction, presence: true
  validates :source_type, presence: true
  validates :url, presence: true

  def country_code
    country&.code
  end
end
