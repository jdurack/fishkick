class AddPrimaryImageToSite < ActiveRecord::Migration
  def change
    add_column :sites, :primary_image, :string
  end
end
