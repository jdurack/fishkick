class AddSiteType < ActiveRecord::Migration
  def change
    add_column :sites, :type, :integer, default: 0
  end
end
