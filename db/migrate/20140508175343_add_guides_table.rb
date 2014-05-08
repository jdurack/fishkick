class AddGuidesTable < ActiveRecord::Migration
  def change
    create_table :guides do |t|
      t.string :first_name
      t.string :last_name
      t.string :phone_number
      t.string :email_address
      t.string :image

      t.timestamps
    end
  end
end
