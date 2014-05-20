class Admin::GuidesController < ApplicationController

  def index
    @guides = Guide.all.order('last_name ASC')
  end

  def show
    @guide = Guide.find(params[:id])
  end

  def edit
    @guide = Guide.find(params[:id])
    unless @guide
      redirect_to(:admin_guides)
    end
  end

  def destroy
    @guide = Guide.find(params[:id])
    @guide.destroy
    redirect_to(:admin_guides)
  end

  def create
    @guide = Guide.new(guide_params)
    @guide.save
    redirect_to(:admin_guides)
  end

  def new
    @guide = Guide.new
  end

  def update
    if params[:commit] == 'Cancel'
      redirect_to :admin_guides
      return
    end
    @guide = Guide.find(params[:id])
    if @guide.update(guide_params)
      redirect_to(:admin_guides)
    else
      render 'edit'
    end
  end

  private
    def guide_params
      params.require(:guide).permit(:first_name, :last_name, :phone_number, :email_address, :primary_image, :is_active)
    end

end
