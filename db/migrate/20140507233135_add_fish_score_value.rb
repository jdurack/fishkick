class AddFishScoreValue < ActiveRecord::Migration
  def change
    add_column :fish_scores, :value, :decimal
    add_index :fish_scores, [:site_id, :fish_id, :date], :unique => true
  end
end
