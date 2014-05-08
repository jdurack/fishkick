class AddMaxScoreToSiteFishInfo < ActiveRecord::Migration
  def change
    add_column :site_fish_infos, :max_score, :integer
  end
end
