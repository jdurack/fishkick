class AddBasicSiteColumns < ActiveRecord::Migration
  def change
    add_column :sites, :name, :string
    add_column :sites, :name_url, :string
    add_index :sites, :name_url
  end
end
