class RenameTables < ActiveRecord::Migration
  def change
    rename_table :siteImage, :site_image
    rename_table :siteFishInfo, :site_fish_info
    rename_table :fishScore, :fish_score
  end
end
