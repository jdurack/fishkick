class CreateReportData < ActiveRecord::Migration
  def change
    create_table :report_data do |t|
      t.belongs_to :site
      t.belongs_to :report_data_parameter
      t.datetime :datetime
      t.decimal :value
      
      t.timestamps
    end
  end
end
