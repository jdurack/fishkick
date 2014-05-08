class AddIsActiveToSitesFishAndGuides < ActiveRecord::Migration
  def change
    add_column :sites, :is_active, :boolean
    add_column :fish, :is_active, :boolean
    add_column :guides, :is_active, :boolean
  end
end
