class CreatePrecipitationData < ActiveRecord::Migration
  def change
    create_table :site_precipitation_data do |t|

      t.belongs_to :site
      t.decimal :value
      t.boolean :is_forecast
      t.date :date

      t.timestamps
    end
  end
end
