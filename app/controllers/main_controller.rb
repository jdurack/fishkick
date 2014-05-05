class MainController < ApplicationController

  def home
    @sites = Site.all
  end
  
end