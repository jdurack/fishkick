class Admin::RegistrationsController < Devise::RegistrationsController
  def new
    redirect_to root_path
  end

  def edit
    redirect_to root_path
  end

  def update
    redirect_to root_path
  end

  def cancel
    redirect_to root_path
  end

  def create
    redirect_to root_path
  end

  def destroy
    redirect_to root_path
  end
end