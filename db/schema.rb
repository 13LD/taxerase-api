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

ActiveRecord::Schema[8.1].define(version: 2026_04_25_143000) do
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

  create_table "exchange_rates", force: :cascade do |t|
    t.string "base_currency_code", null: false
    t.datetime "created_at", null: false
    t.datetime "fetched_at", null: false
    t.string "provider", null: false
    t.string "quote_currency_code", null: false
    t.date "rate_date", null: false
    t.decimal "rate_value", precision: 12, scale: 6, null: false
    t.string "source_name", null: false
    t.string "source_url", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "base_currency_code", "quote_currency_code", "rate_date"], name: "idx_exchange_rates_provider_pair_date", unique: true
    t.index ["provider", "base_currency_code", "rate_date"], name: "idx_exchange_rates_provider_base_date"
  end

  create_table "official_tax_sources", force: :cascade do |t|
    t.string "authority_name", null: false
    t.bigint "country_id", null: false
    t.datetime "created_at", null: false
    t.string "jurisdiction", null: false
    t.string "key", null: false
    t.date "last_verified_on"
    t.text "notes"
    t.date "published_on"
    t.string "source_type", null: false
    t.integer "tax_year"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["country_id"], name: "index_official_tax_sources_on_country_id"
    t.index ["key"], name: "index_official_tax_sources_on_key", unique: true
  end

  create_table "report_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.date "event_date", null: false
    t.string "event_type", null: false
    t.string "key", null: false
    t.integer "position", default: 1, null: false
    t.bigint "tax_report_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.date "window_end_date"
    t.date "window_start_date"
    t.index ["event_date"], name: "index_report_events_on_event_date"
    t.index ["tax_report_id", "key"], name: "index_report_events_on_tax_report_id_and_key", unique: true
    t.index ["tax_report_id"], name: "index_report_events_on_tax_report_id"
  end

  create_table "report_workflows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "key", null: false
    t.string "name", null: false
    t.integer "position", default: 1, null: false
    t.bigint "tax_report_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tax_report_id", "key"], name: "index_report_workflows_on_tax_report_id_and_key", unique: true
    t.index ["tax_report_id"], name: "index_report_workflows_on_tax_report_id"
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
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.string "name", null: false
    t.string "region"
    t.bigint "tax_rule_set_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tax_rule_set_id", "key"], name: "index_tax_regimes_on_tax_rule_set_id_and_key", unique: true
    t.index ["tax_rule_set_id"], name: "index_tax_regimes_on_tax_rule_set_id"
  end

  create_table "tax_reports", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.bigint "country_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.string "name", null: false
    t.integer "tax_year", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id", "tax_year", "key"], name: "index_tax_reports_on_country_id_and_tax_year_and_key", unique: true
    t.index ["country_id"], name: "index_tax_reports_on_country_id"
  end

  create_table "tax_rule_sets", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.bigint "country_id", null: false
    t.datetime "created_at", null: false
    t.string "key", default: "default", null: false
    t.string "name", null: false
    t.text "notes"
    t.date "published_on"
    t.string "release_version", default: "seeded-v1", null: false
    t.string "status", default: "published", null: false
    t.integer "tax_year", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id", "tax_year", "key"], name: "index_tax_rule_sets_on_country_id_and_tax_year_and_key", unique: true
    t.index ["country_id", "tax_year", "status"], name: "index_tax_rule_sets_on_country_id_and_tax_year_and_status"
    t.index ["country_id"], name: "index_tax_rule_sets_on_country_id"
  end

  create_table "tax_source_usages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "label", null: false
    t.text "notes"
    t.bigint "official_tax_source_id", null: false
    t.integer "position", default: 1, null: false
    t.bigint "tax_regime_id", null: false
    t.datetime "updated_at", null: false
    t.string "usage_type", null: false
    t.index ["official_tax_source_id"], name: "index_tax_source_usages_on_official_tax_source_id"
    t.index ["tax_regime_id", "official_tax_source_id", "usage_type"], name: "idx_tax_source_usages_unique_link", unique: true
    t.index ["tax_regime_id"], name: "index_tax_source_usages_on_tax_regime_id"
  end

  add_foreign_key "official_tax_sources", "countries"
  add_foreign_key "report_events", "tax_reports"
  add_foreign_key "report_workflows", "tax_reports"
  add_foreign_key "tax_brackets", "tax_regimes"
  add_foreign_key "tax_parameters", "tax_regimes"
  add_foreign_key "tax_regimes", "tax_rule_sets"
  add_foreign_key "tax_reports", "countries"
  add_foreign_key "tax_rule_sets", "countries"
  add_foreign_key "tax_source_usages", "official_tax_sources"
  add_foreign_key "tax_source_usages", "tax_regimes"
end
