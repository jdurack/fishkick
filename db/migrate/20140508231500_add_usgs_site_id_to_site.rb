class AddUsgsSiteIdToSite < ActiveRecord::Migration
  def change
    add_column :sites, :usgs_site_id, :string
  end
end
