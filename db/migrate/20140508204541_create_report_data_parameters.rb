class CreateReportDataParameters < ActiveRecord::Migration
  def change
    create_table :report_data_parameters do |t|

      t.string :name
      t.string :usgs_parameter_code
      t.string :units
      t.string :units_abbreviation
      t.boolean :is_active

      t.timestamps
    end
  end
end
