class TaxSourceUsage < ApplicationRecord
  belongs_to :tax_regime
  belongs_to :official_tax_source

  validates :usage_type, presence: true
  validates :label, presence: true
  validates :position, presence: true
  validates :official_tax_source_id, uniqueness: { scope: %i[tax_regime_id usage_type], message: "is already linked for this regime and usage type" }
end
