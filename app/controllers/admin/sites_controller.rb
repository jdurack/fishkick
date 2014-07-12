class Admin::SitesController < AdminController

  def index
    @sites = Site.all.order('name ASC')
  end

  def show
    @site = Site.find(params[:id])
  end

  def edit
    @site = Site.find(params[:id])
    add_site_fish_infos(@site)
    unless @site
      redirect_to(:admin_sites)
    end
  end

  def destroy
    @site = Site.find(params[:id])
    @site.destroy
    redirect_to(:admin_sites)
  end

  def create
    @site = Site.create(site_params)
    redirect_to(:admin_sites)
  end

  def new
    @site = Site.new
    add_site_fish_infos(@site)
    @fish = Fish.all
  end

  def update
    if params[:commit] == 'Cancel'
      redirect_to :admin_sites
      return
    end
    @site = Site.find(params[:id])
    @site.update(site_params)
    redirect_to(:admin_sites)
  end

  private
    def site_params
      params.require(:site).permit(:name, :name_url, :is_active, :primary_image, :description, :usgs_site_id, :water_body_type,
        site_fish_infos_attributes: [:id, :fish_id, :is_active, :max_score, :month_value_0, :month_value_1, :month_value_2, :month_value_3, :month_value_4, :month_value_5, :month_value_6, :month_value_7, :month_value_8, :month_value_9, :month_value_10, :month_value_11],
        site_images_attributes: [:id, :image, :image_cache, :_destroy],
        site_map_lines_attributes: [:id, :line_data, :_destroy])
    end

    def add_site_fish_infos(site)
      fish = Fish.all
      fish.each do |fish|
        existingSFI = site.site_fish_infos.select { |sfi| sfi.fish_id == fish.id }
        unless existingSFI.size() > 0
          site.site_fish_infos.push SiteFishInfo.new({:site_id => site.id, :fish_id => fish.id})
        end
      end
    end

end