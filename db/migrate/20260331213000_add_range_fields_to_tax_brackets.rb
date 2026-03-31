class AddRangeFieldsToTaxBrackets < ActiveRecord::Migration[8.1]
  def change
    add_column :tax_brackets, :lower_bound, :decimal, precision: 12, scale: 2
    add_column :tax_brackets, :base_min, :decimal, precision: 12, scale: 2
    add_column :tax_brackets, :base_max, :decimal, precision: 12, scale: 2
    add_column :tax_brackets, :label, :string
  end
end
