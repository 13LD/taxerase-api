class TaxRegime < ApplicationRecord
  belongs_to :country
  has_many :tax_brackets, dependent: :destroy
  has_many :tax_parameters, dependent: :destroy
  has_many :tax_source_usages, dependent: :destroy
  has_many :official_tax_sources, through: :tax_source_usages

  validates :key, presence: true
  validates :name, presence: true
  validates :tax_year, presence: true
  validates :category, presence: true
  validates :key, uniqueness: { scope: %i[country_id tax_year] }

  def brackets_for(group)
    bracket_records_for(group).map { |bracket| [ bracket.upper_bound&.to_d, bracket.rate.to_d ] }
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

  def parameter_text(key)
    tax_parameters.find { |parameter| parameter.key == key }&.value_text
  end

  def parameter_text!(key)
    parameter_text(key) || raise(KeyError, "Missing tax parameter #{key} for #{self.key}")
  end

  def source_links
    usages = if association(:tax_source_usages).loaded?
      tax_source_usages
    else
      tax_source_usages.includes(:official_tax_source)
    end

    usages.sort_by(&:position).map do |usage|
      {
        label: usage.label,
        href: usage.official_tax_source.url,
        usage_type: usage.usage_type,
        authority_name: usage.official_tax_source.authority_name,
        jurisdiction: usage.official_tax_source.jurisdiction,
        tax_year: usage.official_tax_source.tax_year,
        notes: usage.notes.presence || usage.official_tax_source.notes
      }
    end
  end
end
