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
      redirect_to(:admin_sites)
    end
    @fish = Fish.all
    puts 'FISH: ' + @fish.inspect
  end

  def destroy
    @site = Site.find(params[:id])
    @site.destroy
    redirect_to(:admin_sites)
  end

  def create
    @site = Site.new(site_params)
    @site.save
    redirect_to(:admin_sites)
  end

  def new
    @site = Site.new
    @fish = Fish.all
  end

  def update
    if params[:commit] == 'Cancel'
      redirect_to :admin_sites
      return
    end
    @site = Site.find(params[:id])
    if @site.update(site_params)
      redirect_to(:admin_sites)
    else
      render 'edit'
    end
  end

  private
    def site_params
      params.require(:site).permit(:name, :name_url, :description)
    end

end