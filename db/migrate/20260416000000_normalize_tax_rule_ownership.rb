class NormalizeTaxRuleOwnership < ActiveRecord::Migration[8.1]
  class MigrationCountry < ActiveRecord::Base
    self.table_name = "countries"
  end

  class MigrationOfficialTaxSource < ActiveRecord::Base
    self.table_name = "official_tax_sources"
  end

  class MigrationTaxRegime < ActiveRecord::Base
    self.table_name = "tax_regimes"
  end

  class MigrationTaxRuleSet < ActiveRecord::Base
    self.table_name = "tax_rule_sets"
  end

  def up
    create_table :tax_rule_sets do |t|
      t.references :country, null: false, foreign_key: true
      t.integer :tax_year, null: false
      t.string :key, null: false, default: "default"
      t.string :name, null: false
      t.string :release_version, null: false, default: "seeded-v1"
      t.string :status, null: false, default: "published"
      t.boolean :active, null: false, default: true
      t.date :published_on
      t.text :notes

      t.timestamps
    end

    add_index :tax_rule_sets, %i[country_id tax_year key], unique: true
    add_index :tax_rule_sets, %i[country_id tax_year status]

    add_reference :tax_regimes, :tax_rule_set, foreign_key: true
    backfill_tax_rule_sets!
    change_column_null :tax_regimes, :tax_rule_set_id, false

    remove_index :tax_regimes, column: %i[country_id tax_year key]
    add_index :tax_regimes, %i[tax_rule_set_id key], unique: true
    remove_reference :tax_regimes, :country, foreign_key: true
    remove_column :tax_regimes, :tax_year, :integer

    add_reference :official_tax_sources, :country, foreign_key: true
    backfill_official_tax_source_countries!
    change_column_null :official_tax_sources, :country_id, false
    remove_column :official_tax_sources, :country_code, :string
  end

  def down
    add_reference :tax_regimes, :country, foreign_key: true
    add_column :tax_regimes, :tax_year, :integer
    restore_tax_regime_country_year!
    change_column_null :tax_regimes, :country_id, false
    change_column_null :tax_regimes, :tax_year, false

    remove_index :tax_regimes, column: %i[tax_rule_set_id key]
    add_index :tax_regimes, %i[country_id tax_year key], unique: true
    remove_reference :tax_regimes, :tax_rule_set, foreign_key: true

    add_column :official_tax_sources, :country_code, :string
    restore_official_tax_source_country_codes!
    change_column_null :official_tax_sources, :country_code, false
    remove_reference :official_tax_sources, :country, foreign_key: true

    drop_table :tax_rule_sets
  end

  private

  def backfill_tax_rule_sets!
    MigrationTaxRegime.reset_column_information
    MigrationTaxRuleSet.reset_column_information

    MigrationTaxRegime.distinct.pluck(:country_id, :tax_year).each do |country_id, tax_year|
      country = MigrationCountry.find(country_id)
      rule_set = MigrationTaxRuleSet.create!(
        country_id: country_id,
        tax_year: tax_year,
        key: "default",
        name: "#{country.name} #{tax_year} seeded tax rules",
        release_version: "seeded-v1",
        status: "published",
        active: true,
        created_at: Time.current,
        updated_at: Time.current
      )

      MigrationTaxRegime
        .where(country_id: country_id, tax_year: tax_year)
        .update_all(tax_rule_set_id: rule_set.id, updated_at: Time.current)
    end
  end

  def backfill_official_tax_source_countries!
    MigrationOfficialTaxSource.reset_column_information

    MigrationOfficialTaxSource.find_each do |source|
      country = MigrationCountry.find_by!(code: source.country_code)
      source.update_columns(country_id: country.id, updated_at: Time.current)
    end
  end

  def restore_tax_regime_country_year!
    MigrationTaxRegime.reset_column_information
    MigrationTaxRuleSet.reset_column_information

    MigrationTaxRegime.find_each do |regime|
      rule_set = MigrationTaxRuleSet.find(regime.tax_rule_set_id)
      regime.update_columns(
        country_id: rule_set.country_id,
        tax_year: rule_set.tax_year,
        updated_at: Time.current
      )
    end
  end

  def restore_official_tax_source_country_codes!
    MigrationOfficialTaxSource.reset_column_information

    MigrationOfficialTaxSource.find_each do |source|
      country = MigrationCountry.find(source.country_id)
      source.update_columns(country_code: country.code, updated_at: Time.current)
    end
  end
end
