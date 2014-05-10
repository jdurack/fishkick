class MainController < ApplicationController

  def home
    @sites = Site.where({:is_active => true})
  end

  def about
  end

  def faq
  end

  def contact
  end
  
end