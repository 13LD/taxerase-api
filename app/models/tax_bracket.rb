class TaxBracket < ApplicationRecord
  belongs_to :tax_regime

  validates :bracket_group, presence: true
  validates :position, presence: true
  validates :position, uniqueness: { scope: %i[tax_regime_id bracket_group] }
  validate :requires_rate_or_base_range

  private

  def requires_rate_or_base_range
    return if rate.present?
    return if base_min.present?

    errors.add(:base, "Tax bracket must define a rate or a base_min value")
  end
end
