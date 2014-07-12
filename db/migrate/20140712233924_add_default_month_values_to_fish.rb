class AddDefaultMonthValuesToFish < ActiveRecord::Migration
  def change
    add_column :fish, :month_value_0, :decimal
    add_column :fish, :month_value_1, :decimal
    add_column :fish, :month_value_2, :decimal
    add_column :fish, :month_value_3, :decimal
    add_column :fish, :month_value_4, :decimal
    add_column :fish, :month_value_5, :decimal
    add_column :fish, :month_value_6, :decimal
    add_column :fish, :month_value_7, :decimal
    add_column :fish, :month_value_8, :decimal
    add_column :fish, :month_value_9, :decimal
    add_column :fish, :month_value_10, :decimal
    add_column :fish, :month_value_11, :decimal
  end
end
