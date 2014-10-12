class ReportCommentsController < ApplicationController

  def create
    @report_comment = ReportComment.new(report_comment_params)
    @report_comment.datetime = DateTime.now
    @report_comment.save
    render json: @report_comment
    AdminMailer.report_comment_added_email(@report_comment).deliver
  end

  private
    def report_comment_params
      params.require(:report_comment).permit(:site_id, :comment)
    end

end