class RenameSiteType < ActiveRecord::Migration
  def change
    rename_column :sites, :type, :water_body_type
  end
end
