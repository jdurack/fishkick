class Site < ActiveRecord::Base

  validate :min_discharge_must_be_less_than_max_discharge

  has_many :site_fish_infos, dependent: :destroy
  has_many :fish, -> { order 'name DESC' }, through: :site_fish_infos
  has_many :fish_scores, -> { where(fish_scores: {date: Date.today}) }, dependent: :destroy
  has_many :site_images, dependent: :destroy
  has_many :site_map_lines, dependent: :destroy
  has_many :report_comments, dependent: :destroy

  accepts_nested_attributes_for :site_fish_infos
  accepts_nested_attributes_for :site_map_lines, allow_destroy: true
  accepts_nested_attributes_for :site_images, allow_destroy: true
  accepts_nested_attributes_for :report_comments, allow_destroy: true

  enum water_body_type: [ :stream, :lake ]

  mount_uploader :primary_image, SitePrimaryImageUploader

  def min_discharge_must_be_less_than_max_discharge
    if self.min_stream_flow_cfs and self.max_stream_flow_cfs and self.min_stream_flow_cfs >= self.max_stream_flow_cfs
      errors.add(:min_stream_flow_cfs, "Min discharge must be less than max discharge")
    end
  end

  def updateMapCenter(paramsIn)
    center = self.getMapCenter()
    if !center.blank?
      update(center)
    end
  end

  def hasGeoData()
    if !self.latitude.blank? and !self.longitude.blank?
      return true
    elsif !self.site_map_lines.blank?
      return true
    end
    return false
  end

  def getMapCenter()
    numPoints = 0
    totalLatitude = 0.0
    totalLongitude = 0.0
    self.getMapLineData().each do |mld|
      mld.each do |point|
        totalLatitude += point['latitude'].to_f
        totalLongitude += point['longitude'].to_f
        numPoints += 1
      end
    end
    center = nil
    if numPoints > 0
      center = {'latitude' => totalLatitude / numPoints, 'longitude' => totalLongitude / numPoints}
    end
    return center
  end

  def convertMapPointsToData(mapPoints)
    data = []
    dataPoints = mapPoints.split(/\)\(/)
    dataPoints.each do |d|
      d = d.gsub('(','').gsub(')','').gsub(' ','')
      commaSplit = d.split(',')
      next unless commaSplit.length == 2
      data.push( {'latitude' => commaSplit[0], 'longitude' => commaSplit[1]} )
    end
    return data
  end

  def getMapLineData()
    mapLineData = []
    self.site_map_lines.each do |mld|
      mapLineData.push(self.convertMapPointsToData(mld.line_data))
    end
    return mapLineData
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

    if !@usgsData.blank?
      return @usgsData
    end

    usgsDataParameter = self.getUSGSDataParameter()
    startDay = ( Date.today - Settings.report.usgs_data_lookback_days.days ).to_s
    whereString = "site_id = " + self.id.to_s + " AND datetime >= '" + startDay + "'" + " AND report_data_parameter_id = " + usgsDataParameter.id.to_s
    @usgsData = ReportData.where(whereString)
    return @usgsData
  end

  def getMostRecentUSGSData()
    if !@mostRecentUSGSData.blank?
      return @mostRecentUSGSData
    end

    usgsDataParameter = self.getUSGSDataParameter()
    whereString = "site_id = " + self.id.to_s + " AND report_data_parameter_id = " + usgsDataParameter.id.to_s
    @mostRecentUSGSData = ReportData.where(whereString).order(datetime: :desc).first

    return @mostRecentUSGSData
  end

  def hasActiveSiteFishInfos()
    self.site_fish_infos.each do |sfi|
      if sfi.is_active and sfi.fish.is_active
        return true
      end
    end
    return false
  end

  def hasUSGSData()
    usgsData = self.getUSGSData()
    return !usgsData.blank?
  end

  def hasWeatherData()
    weatherData = self.getWeatherData()
    return !weatherData.blank?
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
      @weatherData[dataDay] = {'value' => nil, 'date' => dataDay}
      dataDay = dataDay + 1.day
    end

    weatherDataFromDB.each do |weatherDatum|
      @weatherData[weatherDatum.date]['value'] = weatherDatum.value
    end
    
    return @weatherData
  end

  def getWeatherDataTitle()
    return 'Precipitation (inches)'
  end
end