class Admin::FishController < AdminController

  def index
    @fish = Fish.all.order('name ASC')
  end

  def show
    @fish = Fish.find(params[:id])
  end

  def edit
    @fish = Fish.find(params[:id])
    unless @fish
      redirect_to(:admin_fish_index)
    end
  end

  def destroy
    @fish = Fish.find(params[:id])
    @fish.destroy
    redirect_to(:admin_fish_index)
  end

  def create
    @fish = Fish.new(fish_params)
    @fish.save
    redirect_to(:admin_fish_index)
  end

  def new
    @fish = Fish.new
  end

  def update
    if params[:commit] == 'Cancel'
      redirect_to :admin_fish_index
      return
    end
    @fish = Fish.find(params[:id])
    if @fish.update(fish_params)
      redirect_to(:admin_fish_index)
    else
      render 'edit'
    end
  end

  private
    def fish_params
      params.require(:fish).permit(:name, :image, :is_active, :month_value_0, :month_value_1, :month_value_2, :month_value_3, :month_value_4, :month_value_5, :month_value_6, :month_value_7, :month_value_8, :month_value_9, :month_value_10, :month_value_11)
    end

end