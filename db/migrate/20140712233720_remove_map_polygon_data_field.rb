class RemoveMapPolygonDataField < ActiveRecord::Migration
  def change
    remove_column :sites, :map_polygon_data
  end
end
