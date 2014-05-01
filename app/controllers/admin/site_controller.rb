class Admin::SiteController < AdminController

  def index
    @sites = Site.all
    puts 'sites: ' + @sites.inspect
  end

  def edit
    @site = Site.find_by name_url: params[:id]
  end
end
