class PluralizeTableNames < ActiveRecord::Migration
  def change
    rename_table :site_image, :site_images
    rename_table :site_fish_info, :site_fish_infos
    rename_table :fish_score, :fish_scores
  end
end
