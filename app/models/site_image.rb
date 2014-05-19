class SiteImage < ActiveRecord::Base

  belongs_to :site

  mount_uploader :image, SiteImageUploader 
end
