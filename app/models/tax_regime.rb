class TaxRegime < ApplicationRecord
  belongs_to :tax_rule_set
  has_one :country, through: :tax_rule_set
  has_many :tax_brackets, dependent: :destroy
  has_many :tax_parameters, dependent: :destroy
  has_many :tax_source_usages, dependent: :destroy
  has_many :official_tax_sources, through: :tax_source_usages

  delegate :country_id, :tax_year, :release_version, to: :tax_rule_set

  validates :key, presence: true
  validates :name, presence: true
  validates :category, presence: true
  validates :key, uniqueness: { scope: :tax_rule_set_id }

  scope :for_country, ->(country) {
    joins(:tax_rule_set).where(tax_rule_sets: { country_id: country&.id || country })
  }
  scope :for_country_year, ->(country:, tax_year:) {
    for_country(country).where(tax_rule_sets: { tax_year: tax_year })
  }
  scope :for_tax_year, ->(tax_year) {
    joins(:tax_rule_set).where(tax_rule_sets: { tax_year: tax_year })
  }
  scope :ordered_for_catalog, -> {
    includes(:tax_rule_set)
      .joins(:tax_rule_set)
      .order(Arel.sql("tax_rule_sets.tax_year ASC"), :category, :region, :name)
  }
  scope :with_rule_data, -> {
    includes(:country, :tax_brackets, :tax_parameters, tax_source_usages: :official_tax_source)
  }
  scope :with_source_data, -> {
    includes(:country, :tax_parameters, tax_source_usages: :official_tax_source)
  }
  scope :with_routing_data, -> {
    includes(:tax_rule_set, :tax_parameters)
  }

  def self.default_supported_key_for(country:, tax_year:, supported_methods:, category: "employee")
    supported = for_country_year(country:, tax_year:)
      .joins(:tax_parameters)
      .where(
        active: true,
        category:,
        tax_parameters: {
          key: "calculation_method",
          value_text: supported_methods
        }
      )
      .order(:region, :name)
      .pick(:key)

    supported || for_country_year(country:, tax_year:)
      .where(active: true, category:)
      .order(:region, :name)
      .pick(:key)
  end

  def self.supported_tax_years_for(country:, supported_methods:)
    public_catalog_data_for(country:, supported_methods:).fetch(:tax_year_options)
  end

  def self.supported_categories_for(country:, supported_methods:)
    public_catalog_data_for(country:, supported_methods:).fetch(:categories)
  end

  def self.public_catalog_options_for(country:, supported_methods:)
    public_catalog_data_for(country:, supported_methods:).fetch(:regime_options)
  end

  def self.public_catalog_data_for(country:, supported_methods:)
    rows = public_catalog_rows_for(country:, supported_methods:)

    {
      tax_year_options: rows.map { |row| row.fetch(:tax_year) }.uniq.sort,
      categories: rows.map { |row| row.fetch(:category) }.uniq,
      regime_options: rows
    }
  end

  def self.public_catalog_rows_by_country(supported_methods_by_country:)
    rows = joins(tax_rule_set: :country)
      .joins(:tax_parameters)
      .where(active: true, tax_parameters: { key: "calculation_method" })
      .order(
        Arel.sql("countries.code ASC"),
        Arel.sql("tax_rule_sets.tax_year ASC"),
        :category,
        :region,
        :name
      )
      .pluck(
        Arel.sql("countries.code"),
        Arel.sql("countries.name"),
        Arel.sql("countries.currency_code"),
        :key,
        :name,
        :region,
        :category,
        Arel.sql("tax_rule_sets.tax_year"),
        Arel.sql("tax_parameters.value_text")
      )

    rows
      .select { |row| supported_methods_by_country.fetch(row[0], []).include?(row[8]) }
      .group_by(&:first)
      .transform_values do |country_rows|
      first_row = country_rows.first
      {
        country: {
          code: first_row[0],
          name: first_row[1],
          currency_code: first_row[2]
        },
        regime_options: country_rows.map do |row|
          {
            key: row[3],
            name: row[4],
            region: row[5],
            category: row[6],
            tax_year: row[7]
          }
        end
      }
    end
  end

  def self.public_regime_options_for(country:, catalog_options:)
    options_by_pair = catalog_options.index_by { |regime| [ regime.fetch(:key), regime.fetch(:tax_year) ] }

    rows = for_country(country)
      .joins(:tax_rule_set)
      .where(key: catalog_options.map { |regime| regime.fetch(:key) }.uniq)
      .order(Arel.sql("tax_rule_sets.tax_year ASC"), :category, :region, :name)
      .pluck(
        :id,
        :key,
        :name,
        :region,
        :category,
        Arel.sql("tax_rule_sets.tax_year"),
        :description
      )
      .select { |_id, key, _name, _region, _category, tax_year, _description| options_by_pair.key?([ key, tax_year ]) }

    sources_by_regime_id = source_links_by_regime_id(rows.map(&:first))

    rows.map do |id, key, name, region, category, tax_year, description|
      {
        key: key,
        name: name,
        region: region,
        category: category,
        tax_year: tax_year,
        description: description,
        supported: true,
        status: "Live",
        sources: sources_by_regime_id.fetch(id, [])
      }
    end
  end

  def self.source_links_by_regime_id(regime_ids)
    return {} if regime_ids.empty?

    TaxSourceUsage
      .joins(:official_tax_source)
      .where(tax_regime_id: regime_ids)
      .order(:tax_regime_id, :position)
      .pluck(
        :tax_regime_id,
        :label,
        :usage_type,
        :notes,
        Arel.sql("official_tax_sources.url"),
        Arel.sql("official_tax_sources.authority_name"),
        Arel.sql("official_tax_sources.jurisdiction"),
        Arel.sql("official_tax_sources.tax_year"),
        Arel.sql("official_tax_sources.notes")
      )
      .group_by(&:first)
      .transform_values do |rows|
        rows.map do |_tax_regime_id, label, usage_type, usage_notes, href, authority_name, jurisdiction, tax_year, source_notes|
          {
            label: label,
            href: href,
            usage_type: usage_type,
            authority_name: authority_name,
            jurisdiction: jurisdiction,
            tax_year: tax_year,
            notes: usage_notes.presence || source_notes
          }
        end
      end
  end
  private_class_method :source_links_by_regime_id

  def self.public_catalog_rows_for(country:, supported_methods:)
    supported_rule_scope(country:, supported_methods:)
      .distinct
      .order(Arel.sql("tax_rule_sets.tax_year ASC"), :category, :region, :name)
      .pluck(
        :key,
        :name,
        :region,
        :category,
        Arel.sql("tax_rule_sets.tax_year")
      )
      .map do |key, name, region, category, tax_year|
        {
          key:,
          name:,
          region:,
          category:,
          tax_year:
        }
      end
  end

  def self.public_catalog_option_for(country:, tax_year:, key:, supported_methods:)
    row = supported_rule_scope(country:, supported_methods:)
      .where(key:)
      .where(tax_rule_sets: { tax_year: tax_year })
      .pick(
        :key,
        :name,
        :region,
        :category,
        Arel.sql("tax_rule_sets.tax_year")
      )
    return unless row

    key, name, region, category, tax_year = row
    {
      key:,
      name:,
      region:,
      category:,
      tax_year:
    }
  end

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

  def self.supported_rule_scope(country:, supported_methods:)
    for_country(country)
      .joins(:tax_parameters)
      .where(
        active: true,
        tax_parameters: {
          key: "calculation_method",
          value_text: supported_methods
        }
      )
  end
  private_class_method :supported_rule_scope
end
