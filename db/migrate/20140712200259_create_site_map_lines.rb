class CreateSiteMapLines < ActiveRecord::Migration
  def change
    create_table :site_map_lines do |t|

      t.belongs_to :site
      t.text :line_data

      t.timestamps
    end
  end
end
