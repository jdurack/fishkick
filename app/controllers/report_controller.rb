class ReportController < ApplicationController

  def view
    @site = Site.find_by name_url: params[:site_name_url]
    @guides = Guide.where({:is_active => true})
  end

end