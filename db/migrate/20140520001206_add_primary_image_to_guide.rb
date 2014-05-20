class AddPrimaryImageToGuide < ActiveRecord::Migration
  def change
    add_column :guides, :primary_image, :string
  end
end
