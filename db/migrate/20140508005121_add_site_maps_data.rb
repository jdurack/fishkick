class AddSiteMapsData < ActiveRecord::Migration
  def change
    add_column :sites, :map_polygon_data, :text
    add_column :sites, :latitude, :text
    add_column :sites, :longitude, :text
  end
end