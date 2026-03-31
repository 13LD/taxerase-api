class CreateTaxRuleTables < ActiveRecord::Migration[8.1]
  def change
    create_table :countries do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :currency_code, null: false, default: "EUR"

      t.timestamps
    end

    add_index :countries, :code, unique: true

    create_table :tax_regimes do |t|
      t.references :country, null: false, foreign_key: true
      t.string :key, null: false
      t.string :name, null: false
      t.integer :tax_year, null: false
      t.string :category, null: false
      t.string :region
      t.boolean :active, null: false, default: true
      t.text :description

      t.timestamps
    end

    add_index :tax_regimes, %i[country_id tax_year key], unique: true

    create_table :tax_brackets do |t|
      t.references :tax_regime, null: false, foreign_key: true
      t.string :bracket_group, null: false
      t.integer :position, null: false
      t.decimal :upper_bound, precision: 12, scale: 2
      t.decimal :rate, precision: 8, scale: 5, null: false

      t.timestamps
    end

    add_index :tax_brackets, %i[tax_regime_id bracket_group position], unique: true

    create_table :tax_parameters do |t|
      t.references :tax_regime, null: false, foreign_key: true
      t.string :key, null: false
      t.decimal :value_decimal, precision: 12, scale: 5
      t.string :value_text

      t.timestamps
    end

    add_index :tax_parameters, %i[tax_regime_id key], unique: true
  end
end
