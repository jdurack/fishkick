class Site < ActiveRecord::Base

  has_many :site_fish_infos
  has_many :fish, through: :site_fish_infos
  has_many :fish_scores, through: :site_fish_infos
  has_many :site_images
end