class TaxRegime < ApplicationRecord
  belongs_to :country
  has_many :tax_brackets, dependent: :destroy
  has_many :tax_parameters, dependent: :destroy

  validates :key, presence: true
  validates :name, presence: true
  validates :tax_year, presence: true
  validates :category, presence: true
  validates :key, uniqueness: { scope: %i[country_id tax_year] }

  def brackets_for(group)
    bracket_records_for(group).map { |bracket| [bracket.upper_bound&.to_d, bracket.rate.to_d] }
  end

  def bracket_records_for(group)
    tax_brackets
      .select { |bracket| bracket.bracket_group == group }
      .sort_by(&:position)
  end

  def bracket_for_amount(group, amount)
    amount_decimal = amount.to_d

    bracket_records_for(group).find do |bracket|
      lower_match = bracket.lower_bound.blank? || amount_decimal >= bracket.lower_bound.to_d
      upper_match = bracket.upper_bound.blank? || amount_decimal <= bracket.upper_bound.to_d

      lower_match && upper_match
    end
  end

  def parameter_decimal!(key)
    tax_parameters.find { |parameter| parameter.key == key }&.value_decimal&.to_d ||
      raise(KeyError, "Missing tax parameter #{key} for #{self.key}")
  end
end
