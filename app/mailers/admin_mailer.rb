class AdminMailer < ActionMailer::Base
  default from: "app@fishkick.com"

  @@admin_email = 'admin@fishkick.com'

  def report_comment_added_email(report_comment)
    @report_comment = report_comment
    @site = Site.find(report_comment.site_id)
    mail(to: @@admin_email, subject: 'New report comment for the ' + @site.name)
  end
end
