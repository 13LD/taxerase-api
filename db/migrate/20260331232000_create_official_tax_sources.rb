class CreateOfficialTaxSources < ActiveRecord::Migration[8.1]
  def change
    create_table :official_tax_sources do |t|
      t.string :key, null: false
      t.string :title, null: false
      t.string :authority_name, null: false
      t.string :country_code, null: false
      t.string :jurisdiction, null: false
      t.string :source_type, null: false
      t.string :url, null: false
      t.integer :tax_year
      t.date :published_on
      t.date :last_verified_on
      t.text :notes
      t.timestamps
    end

    add_index :official_tax_sources, :key, unique: true

    create_table :tax_source_usages do |t|
      t.references :tax_regime, null: false, foreign_key: true
      t.references :official_tax_source, null: false, foreign_key: true
      t.string :usage_type, null: false
      t.string :label, null: false
      t.text :notes
      t.integer :position, null: false, default: 1
      t.timestamps
    end

    add_index :tax_source_usages, %i[tax_regime_id official_tax_source_id usage_type], unique: true, name: "idx_tax_source_usages_unique_link"
  end
end
