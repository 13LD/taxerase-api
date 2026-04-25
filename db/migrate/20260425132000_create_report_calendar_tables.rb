class CreateReportCalendarTables < ActiveRecord::Migration[8.1]
  def change
    create_table :tax_reports do |t|
      t.references :country, null: false, foreign_key: true
      t.string :key, null: false
      t.string :name, null: false
      t.integer :tax_year, null: false
      t.text :description
      t.boolean :active, null: false, default: true

      t.timestamps

      t.index [ :country_id, :tax_year, :key ], unique: true
    end

    create_table :report_workflows do |t|
      t.references :tax_report, null: false, foreign_key: true
      t.string :key, null: false
      t.string :name, null: false
      t.text :description, null: false
      t.integer :position, null: false, default: 1

      t.timestamps

      t.index [ :tax_report_id, :key ], unique: true
    end

    create_table :report_events do |t|
      t.references :tax_report, null: false, foreign_key: true
      t.string :key, null: false
      t.string :title, null: false
      t.string :event_type, null: false
      t.date :event_date, null: false
      t.text :description
      t.integer :position, null: false, default: 1

      t.timestamps

      t.index :event_date
      t.index [ :tax_report_id, :key ], unique: true
    end
  end
end
