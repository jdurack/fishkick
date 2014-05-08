class MainController < ApplicationController

  def home
    @sites = Site.where({:is_active => true})
  end
  
end