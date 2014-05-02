class Admin::SitesController < AdminController

  def index
    @sites = Site.all
  end

  def show
    @site = Site.find(params[:id])
  end

  def edit
    @site = Site.find(params[:id])
    unless @site
      redirect_to(:index)
    end
  end

  def create
    @site = Site.new(site_params)
    @site.save
    redirect_to(:admin_sites)
  end

  def new
    @site = Site.new
    puts 'new site: ' + @site.inspect + ', model name: ' + @site.class.name
  end

  def update
    @site = Site.find(params[:id])
    if @site.update(site_params)
      redirect_to(:admin_sites)
    else
      render 'edit'
    end
  end

  private
    def site_params
      params.require(:site).permit(:name, :name_url)
    end

end