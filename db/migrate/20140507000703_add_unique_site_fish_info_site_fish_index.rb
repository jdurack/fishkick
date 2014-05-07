class AddUniqueSiteFishInfoSiteFishIndex < ActiveRecord::Migration
  def change
    add_index :site_fish_infos, [:site_id, :fish_id], :unique => true
  end
end
