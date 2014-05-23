class MainController < ApplicationController

  def home
    @fish_scores = FishScore.where({:date => Date.today})
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