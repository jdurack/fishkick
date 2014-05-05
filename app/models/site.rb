class Site < ActiveRecord::Base

  has_many :siteFishInfos
  has_many :fish, through: :siteFishInfos
  has_many :fishScores, through: :siteFishInfos
  has_many :siteImages
end
