class RenameSiteFishInfoIsActive < ActiveRecord::Migration
  def change
    rename_column :site_fish_infos, :isActive, :is_active
  end
end
