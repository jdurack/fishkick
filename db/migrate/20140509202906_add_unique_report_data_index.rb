class AddUniqueReportDataIndex < ActiveRecord::Migration
  def change
    add_index :report_data, [:site_id, :report_data_parameter_id, :datetime], :unique => true, :name => 'data_point_unique_index'
  end
end
