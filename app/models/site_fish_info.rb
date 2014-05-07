class SiteFishInfo < ActiveRecord::Base
  
  belongs_to :site
  belongs_to :fish
  has_many :fish_scores
end
