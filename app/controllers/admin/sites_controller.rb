class Admin::SitesController < AdminController

  def index
    @sites = Site.all.order('name ASC')
  end

  def show
    @site = Site.find(params[:id])
  end

  def edit
    @site = Site.find(params[:id])
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
    @site = Site.create
    update_site_from_params(@site)
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
    update_site_from_params(@site)
    redirect_to(:admin_sites)
  end

  def update_site_from_params(site)
    add_site_fish_infos( site )
    if @site.update(site_params)
      @site.site_fish_infos.each do |sfi|
        params = site_fish_info_params(sfi.id)
        if !params.blank?
          if ( params['is_active'] == 'on' )
            params['is_active'] = true
          else
            params['is_active'] = false
          end
          sfi.update(params)
        end
      end
    end
  end

  private
    def site_params
      params.require(:site).permit(:name, :name_url, :is_active, :description, :usgs_site_id, :latitude, :longitude, :map_polygon_data, :water_body_type)
    end

    def site_fish_info_params(site_fish_info_id)
      begin
        siteFishInfoParams = params.require('siteFishInfo_' + site_fish_info_id.to_s)
        siteFishInfoParams.permit(:is_active, :max_score, :month_value_0, :month_value_1, :month_value_2, :month_value_3, :month_value_4, :month_value_5, :month_value_6, :month_value_7, :month_value_8, :month_value_9, :month_value_10, :month_value_11)
      rescue ActionController::ParameterMissing
        return false
      end
    end

    def add_site_fish_infos(site)
      fish = Fish.all
      fish.each do |fish|
        existingSFI = site.site_fish_infos.select { |sfi| sfi.fish_id == fish.id }
        unless existingSFI.size() > 0
          site.site_fish_infos.push SiteFishInfo.create({:site_id => site.id, :fish_id => fish.id})
        end
      end
    end

end