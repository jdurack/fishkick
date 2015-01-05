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
    @site.updateMapCenter(site_params)
    if @site.valid?
      redirect_to(:admin_sites)
    else
      render 'new'
    end
  end

  def new
    @site = Site.new
    add_site_fish_infos(@site)
  end

  def update
    if params[:commit] == 'Cancel'
      redirect_to :admin_sites
      return
    end
    @site = Site.find(params[:id])
    @site.update(site_params)
    @site.updateMapCenter(site_params)
    if @site.valid?
      redirect_to(:admin_sites)
    else
      render 'edit'
    end
  end

  private
    def site_params
      params.require(:site).permit(:name, :name_url, :is_active, :primary_image, :description, :usgs_site_id, :water_body_type, :min_stream_flow_cfs, :max_stream_flow_cfs,
        site_fish_infos_attributes: [:id, :fish_id, :is_active, :max_score, :month_value_0, :month_value_1, :month_value_2, :month_value_3, :month_value_4, :month_value_5, :month_value_6, :month_value_7, :month_value_8, :month_value_9, :month_value_10, :month_value_11],
        site_images_attributes: [:id, :image, :image_cache, :_destroy],
        site_map_lines_attributes: [:id, :line_data, :_destroy],
        report_comments_attributes: [:id, :comment, :datetime, :_destroy])
    end

    def add_site_fish_infos(site)
      fish = Fish.all
      fish.each do |fish|
        existingSFI = site.site_fish_infos.select { |sfi| sfi.fish_id == fish.id }
        unless existingSFI.size() > 0
          site.site_fish_infos.push SiteFishInfo.new({:site_id => site.id, :fish_id => fish.id, :month_value_0 => fish.month_value_0, :month_value_1 => fish.month_value_1, :month_value_2 => fish.month_value_2, :month_value_3 => fish.month_value_3, :month_value_4 => fish.month_value_4, :month_value_5 => fish.month_value_5, :month_value_6 => fish.month_value_6, :month_value_7 => fish.month_value_7, :month_value_8 => fish.month_value_8, :month_value_9 => fish.month_value_9, :month_value_10 => fish.month_value_10, :month_value_11 => fish.month_value_11})
        end
      end
    end

end