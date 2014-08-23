class CreateReportComments < ActiveRecord::Migration
  def change
    create_table :report_comments do |t|

      t.belongs_to :site
      t.text :comment
      t.date :date
      t.time :time
      t.boolean :is_autogen

      t.timestamps
    end
  end
end
