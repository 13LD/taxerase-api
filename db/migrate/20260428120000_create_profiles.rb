# frozen_string_literal: true

class CreateProfiles < ActiveRecord::Migration[8.1]
  DEFAULT_COUNTRY_CODE = "ES"
  DEFAULT_PROFILE_TYPE = "employee"

  def up
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :country_code, null: false, default: DEFAULT_COUNTRY_CODE
      t.string :profile_type, null: false, default: DEFAULT_PROFILE_TYPE

      t.timestamps null: false
    end

    add_index :profiles, :country_code
    add_index :profiles, :profile_type

    migrate_selected_country_code_from_users if column_exists?(:users, :selected_country_code)
  end

  def down
    restore_selected_country_code_to_users
    drop_table :profiles, if_exists: true
  end

  private

  def migrate_selected_country_code_from_users
    execute <<~SQL.squish
      INSERT INTO profiles (user_id, country_code, profile_type, created_at, updated_at)
      SELECT users.id,
             COALESCE(NULLIF(users.selected_country_code, ''), '#{DEFAULT_COUNTRY_CODE}'),
             '#{DEFAULT_PROFILE_TYPE}',
             CURRENT_TIMESTAMP,
             CURRENT_TIMESTAMP
      FROM users
      WHERE NOT EXISTS (
        SELECT 1
        FROM profiles
        WHERE profiles.user_id = users.id
      )
    SQL

    remove_index :users, :selected_country_code if index_exists?(:users, :selected_country_code)
    remove_column :users, :selected_country_code
  end

  def restore_selected_country_code_to_users
    unless column_exists?(:users, :selected_country_code)
      add_column :users, :selected_country_code, :string, null: false, default: DEFAULT_COUNTRY_CODE
    end

    add_index :users, :selected_country_code unless index_exists?(:users, :selected_country_code)

    return unless table_exists?(:profiles)

    execute <<~SQL.squish
      UPDATE users
      SET selected_country_code = profiles.country_code
      FROM profiles
      WHERE profiles.user_id = users.id
    SQL
  end
end
