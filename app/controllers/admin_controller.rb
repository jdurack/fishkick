class AdminController < ApplicationController

  before_action :authenticate_admin!

  #def after_sign_in_path_for(admin)
  #  'admin/site/'
  #end
end
