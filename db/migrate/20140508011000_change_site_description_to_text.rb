class ChangeSiteDescriptionToText < ActiveRecord::Migration
  def change
    change_column :sites, :description, :text
  end
end