# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_31_214500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "countries", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "currency_code", default: "EUR", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_countries_on_code", unique: true
  end

  create_table "tax_brackets", force: :cascade do |t|
    t.decimal "base_max", precision: 12, scale: 2
    t.decimal "base_min", precision: 12, scale: 2
    t.string "bracket_group", null: false
    t.datetime "created_at", null: false
    t.string "label"
    t.decimal "lower_bound", precision: 12, scale: 2
    t.integer "position", null: false
    t.decimal "rate", precision: 8, scale: 5
    t.bigint "tax_regime_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "upper_bound", precision: 12, scale: 2
    t.index ["tax_regime_id", "bracket_group", "position"], name: "idx_on_tax_regime_id_bracket_group_position_e563c89903", unique: true
    t.index ["tax_regime_id"], name: "index_tax_brackets_on_tax_regime_id"
  end

  create_table "tax_parameters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.bigint "tax_regime_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "value_decimal", precision: 12, scale: 5
    t.string "value_text"
    t.index ["tax_regime_id", "key"], name: "index_tax_parameters_on_tax_regime_id_and_key", unique: true
    t.index ["tax_regime_id"], name: "index_tax_parameters_on_tax_regime_id"
  end

  create_table "tax_regimes", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "category", null: false
    t.bigint "country_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.string "name", null: false
    t.string "region"
    t.integer "tax_year", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id", "tax_year", "key"], name: "index_tax_regimes_on_country_id_and_tax_year_and_key", unique: true
    t.index ["country_id"], name: "index_tax_regimes_on_country_id"
  end

  add_foreign_key "tax_brackets", "tax_regimes"
  add_foreign_key "tax_parameters", "tax_regimes"
  add_foreign_key "tax_regimes", "countries"
end
