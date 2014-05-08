class Site < ActiveRecord::Base

  has_many :site_fish_infos
  has_many :fish, through: :site_fish_infos
  has_many :fish_scores
  has_many :site_images

  def hasGeoData()
    if !self.latitude.blank? and !self.longitude.blank?
      return true
    elsif !self.map_polygon_data.blank?
      return true
    end
    return false
  end

  def getMapCenter()
    points = self.getMapPolygonPoints()
    totalLatitude = 0.0
    totalLongitude = 0.0
    points.each do |p|
      totalLatitude += p['latitude'].to_f
      totalLongitude += p['longitude'].to_f
    end
    center = {'latitude' => totalLatitude / points.size(), 'longitude' => totalLongitude / points.size()}
    return center
  end

  def getMapZoomLevel()

    if !@zoomLevel.blank?
      return @zoomLevel
    end

    points = self.getMapPolygonPoints()
    if points.blank?
      return 12
    end
    minLatitude = nil
    maxLatitude = nil
    minLongitude = nil
    maxLongitude = nil
    points.each do |p|
      latitude = p['latitude'].to_f
      longitude = p['longitude'].to_f
      if minLatitude.nil? or latitude < minLatitude
        minLatitude = latitude
      end
      if maxLatitude.nil? or latitude > maxLatitude
        maxLatitude = latitude
      end
      if minLongitude.nil? or longitude < minLongitude
        minLongitude = longitude
      end
      if maxLongitude.nil? or longitude > maxLongitude
        maxLongitude = longitude
      end
    end
    distance = Math.sqrt( ( (maxLatitude - minLatitude) ** 2 ) + ( (maxLongitude - minLongitude) ** 2 ) )

    # Zoom level should scale between 10 and 15, with distance calibration bounds of .005 and .222
    @zoomLevel = ( 15 - ( ( ( distance - 0.005 ) / 0.222  ) * 5 ) ).to_i
    if @zoomLevel > 15
      @zoomLevel = 15
    elsif @zoomLevel < 10
      @zoomLevel = 10
    end

    return @zoomLevel
  end

  def getMapPolygonPoints()

    if !@mapPolygonPoints.blank?
      return @mapPolygonPoints
    end

    if self.map_polygon_data.blank?
      return []
    end

    @mapPolygonPoints = []
    polygonData = self.map_polygon_data.split(/\)\(/)
    polygonData.each do |d|
      d = d.gsub('(','').gsub(')','').gsub(' ','')
      commaSplit = d.split(',')
      next unless commaSplit.length == 2
      @mapPolygonPoints.push( {'latitude' => commaSplit[0], 'longitude' => commaSplit[1]} )
    end
    return @mapPolygonPoints
  end
end