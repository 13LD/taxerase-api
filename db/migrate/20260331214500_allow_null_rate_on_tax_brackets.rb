class AllowNullRateOnTaxBrackets < ActiveRecord::Migration[8.1]
  def change
    change_column_null :tax_brackets, :rate, true
  end
end
