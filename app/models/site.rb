class Site < ActiveRecord::Base

  has_many :site_fish_infos
  has_many :fish, -> { order 'name DESC' }, through: :site_fish_infos
  has_many :fish_scores, -> { where(fish_scores: {date: Date.today}) }
  has_many :site_images

  enum water_body_type: [ :stream, :lake ]

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
    @zoomLevel = ( 15 - ( ( ( distance - 0.005 ) / ( 0.222 - 0.005 ) ) * 5 ) ).to_i
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

  def getUSGSDataParameter()

    if !@usgsDataParameter.blank?
      return @usgsDataParameter
    end

    @usgsDataParameter = ReportDataParameter.find(Settings.report.report_data_parameter_id)
    return @usgsDataParameter
  end

  def getUSGSDataLabel()
    usgsDataParameter = self.getUSGSDataParameter()
    label = usgsDataParameter.name
    if usgsDataParameter.units_abbreviation
      label += ' (' + usgsDataParameter.units_abbreviation + ')'
    end
    return label
  end

  def getUSGSData()
    usgsDataParameter = self.getUSGSDataParameter()
    startDay = ( Date.today - Settings.report.usgs_data_lookback_days.days ).to_s
    whereString = "site_id = " + self.id.to_s + " AND datetime >= '" + startDay + "'" + " AND report_data_parameter_id = " + usgsDataParameter.id.to_s
    usgsData = ReportData.where(whereString)
    return usgsData
  end

  def hasActiveSiteFishInfos()
    self.site_fish_infos.each do |sfi|
      if sfi.is_active and sfi.fish.is_active
        return true
      end
    end
    return false
  end

  def hasWeatherData()
    return true
  end

  def getWeatherData()

    if !@weatherData.blank?
      return @weatherData
    end

    startDay = ( Date.today - Settings.report.weather_data_lookback_days.days ).to_s
    whereString = "site_id = " + self.id.to_s + " AND date >= '" + startDay + "'"
    weatherDataFromDB = SitePrecipitationData.where(whereString)
    earliestDataDay = nil
    latestDataDay = nil
    weatherDataFromDB.each do |weatherDatum|
      if ( earliestDataDay.nil? or weatherDatum.date < earliestDataDay )
        earliestDataDay = weatherDatum.date
      end
      if ( latestDataDay.nil? or weatherDatum.date > latestDataDay )
        latestDataDay = weatherDatum.date
      end
    end
    @weatherData = {}
    if earliestDataDay.nil?
      return @weatherData
    end

    dataDay = earliestDataDay
    while dataDay <= latestDataDay
      @weatherData[dataDay] = {'value' => nil, 'is_forecast' => nil}
      dataDay = dataDay + 1.day
    end

    weatherDataFromDB.each do |weatherDatum|
      if weatherDatum.is_forecast
        if @weatherData[weatherDatum.date]['is_forecast'] != false
          @weatherData[weatherDatum.date]['is_forecast'] = true
          @weatherData[weatherDatum.date]['value'] = weatherDatum.value
        end
      else
        @weatherData[weatherDatum.date]['is_forecast'] = false
        @weatherData[weatherDatum.date]['value'] = weatherDatum.value
      end
    end
    
    return @weatherData
  end

  def getWeatherDataTitle()
    return 'Precipitation (inches)'
  end
end