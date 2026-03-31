class TaxParameter < ApplicationRecord
  belongs_to :tax_regime

  validates :key, presence: true, uniqueness: { scope: :tax_regime_id }
  validate :requires_a_value

  private

  def requires_a_value
    return if value_decimal.present? || value_text.present?

    errors.add(:base, "Tax parameter must have either a decimal or text value")
  end
end
