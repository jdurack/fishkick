class AddSitePrecipitationUniqueIndex < ActiveRecord::Migration
  def change
    add_index :site_precipitation_data, [:site_id, :date, :is_forecast], :unique => true, :name => 'site_precipitation_point_unique_index'
  end
end
