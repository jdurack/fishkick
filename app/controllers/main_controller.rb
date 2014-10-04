class MainController < ApplicationController

  def home
    @sites = Site.where({:is_active => true})
    @fish_scores = FishScore.where({:date => Date.today})
    @fish = Fish.where({:is_active => true}).order('name ASC')
  end

  def reports
    @sites = Site.where({:is_active => true})
  end

  def about
  end

  def faq
  end

  def contact
  end
end