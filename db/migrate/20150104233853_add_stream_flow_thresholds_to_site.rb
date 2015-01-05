class AddStreamFlowThresholdsToSite < ActiveRecord::Migration
  def change
    add_column :sites, :min_stream_flow_cfs, :decimal
    add_column :sites, :max_stream_flow_cfs, :decimal
  end
end
