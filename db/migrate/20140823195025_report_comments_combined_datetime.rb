class ReportCommentsCombinedDatetime < ActiveRecord::Migration
  def change
    remove_column :report_comments, :date
    remove_column :report_comments, :time
    add_column :report_comments, :datetime, :datetime
  end
end
