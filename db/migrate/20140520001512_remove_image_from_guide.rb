class RemoveImageFromGuide < ActiveRecord::Migration
  def change
    remove_column :guides, :image
  end
end
