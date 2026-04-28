# frozen_string_literal: true

class NormalizeProfileTypeValues < ActiveRecord::Migration[8.1]
  def up
    return unless table_exists?(:profiles)

    execute <<~SQL.squish
      UPDATE profiles
      SET profile_type = 'employee'
      WHERE profile_type = 'employed'
    SQL

    change_column_default :profiles, :profile_type, from: "employed", to: "employee"
  end

  def down
    return unless table_exists?(:profiles)

    execute <<~SQL.squish
      UPDATE profiles
      SET profile_type = 'employed'
      WHERE profile_type = 'employee'
    SQL

    change_column_default :profiles, :profile_type, from: "employee", to: "employed"
  end
end
