class RemoveDuplicateSiteFishInfoMonthValueFields < ActiveRecord::Migration
  def change
    remove_column :site_fish_infos, :baseScoreJan
    remove_column :site_fish_infos, :baseScoreFeb
    remove_column :site_fish_infos, :baseScoreMar
    remove_column :site_fish_infos, :baseScoreApr
    remove_column :site_fish_infos, :baseScoreMay
    remove_column :site_fish_infos, :baseScoreJun
    remove_column :site_fish_infos, :baseScoreJul
    remove_column :site_fish_infos, :baseScoreAug
    remove_column :site_fish_infos, :baseScoreSep
    remove_column :site_fish_infos, :baseScoreOct
    remove_column :site_fish_infos, :baseScoreNov
    remove_column :site_fish_infos, :baseScoreDec
  end
end