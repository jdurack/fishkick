class Fish < ActiveRecord::Base
  has_many :site_fish_infos

  mount_uploader :image, FishImageUploader
end