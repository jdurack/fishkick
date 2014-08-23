# Calculate Fish Scores
##################################

task :calculate_fish_scores => :environment do
  puts 'calculate_fish_scores running...'
  siteFishInfos = SiteFishInfo.where(is_active: true)
  
  siteFishInfos.each do |sfi|
    next if !sfi.fish.is_active
    today = Date.today
    calculateAndSaveFishScore sfi, Date.today - 1
    calculateAndSaveFishScore sfi, Date.today
    calculateAndSaveFishScore sfi, Date.today + 1
  end
  puts 'calculate_fish_scores done.'
end

def calculateAndSaveFishScore( site_fish_info, date )
  thisMonthIndex = ( date.month - 1 )
  value = (site_fish_info['max_score'].to_f / Settings.max_fish_score) * site_fish_info['month_value_' + thisMonthIndex.to_s].to_f

  findParams = {:site_id => site_fish_info.site_id, :fish_id => site_fish_info.fish_id, :date => date}
  fishScoreData = findParams.merge({ :value => value })
  fishScore = FishScore.find_or_initialize_by(findParams)
  fishScore.update(fishScoreData)
end


# Generate Comments
##################################

task :generate_comments => :environment do
  puts 'generate_comments running...'

  #first, run calculate_fish_scores
  Rake::Task["calculate_fish_scores"].execute

  sites = Site.where(is_active: true)
  
  sites.each do |site|
    today = Date.today
    now = Time.now
    #recent_report_comment = site.report_comments.detect{|c| c.datetime.to_date == Date.today }
    recent_report_comment = nil
    generateComment site, recent_report_comment
  end

  puts 'generate_comments done.'
end

def generateComment( site, recent_report_comment )
  puts 'generateComment...'
  if !recent_report_comment.blank?
    report_comment = recent_report_comment
  else
    report_comment = ReportComment.new do |rc|
      rc.site_id = site.id
      rc.datetime = Time.now
    end
  end
  report_comment.comment = generateCommentText site
  report_comment.comment += generateCommentText site
  report_comment.save()
end


def generateCommentText( site )
  bestFishScore = getBestFishScore site
  bestFishScoreValue = (bestFishScore.value * Settings.max_fish_score).round
  bestFistName = bestFishScore.fish.name.downcase
  siteName = site.name
  siteLeadIn = 'on the'
  if site.water_body_type == 'lake'
    siteLeadIn = 'at'
  end
  comment_text = getCommentTextTemplate bestFishScoreValue
  comment_text.gsub! "{{fishName}}", bestFistName
  comment_text.gsub! "{{siteLeadIn}}", siteLeadIn
  comment_text.gsub! "{{siteName}}", siteName
  return comment_text
end

def getBestFishScore( site )
  fish_scores = site.fish_scores.sort_by {|fs| -fs.value}
  if !fish_scores.blank?
    return fish_scores[0]
  end
  return nil
end

def getCommentTextTemplate( fish_score )
  case fish_score
  when 0
    return "There are absolutely no {{fishName}} {{siteLeadIn}} {{siteName}} now – don’t even waste your time."
  when 1
    return "Pretty lousy time to fish for {{fishName}} {{siteLeadIn}} {{siteName}} at this point – try to find another place to go this week."
  when 2
    return "Not a good week for {{fishName}} {{siteLeadIn}} {{siteName}} – some bites out there, but it’s probably just the locals at this point."
  when 3
    return "Pretty anemic {{siteLeadIn}} {{siteName}} for {{fishName}} today – probably a hit or miss day out there."
  when 4
    return "Not terrible, but not great out there {{siteLeadIn}} {{siteName}} for {{fishName}}, probably worth seeing if there’s anything better out there today."
  when 5
    return "Decent action on {{fishName}} {{siteLeadIn}} {{siteName}} – a good locals day, but don’t drive 4 hours for this!"
  when 6
    return "Solid fishing {{siteLeadIn}} {{siteName}} – caught a few {{fishName}}, but I’ve had better days out there."
  when 7
    return "A pretty good day all around {{siteLeadIn}} {{siteName}} for {{fishName}}. Definitely worth the trip."
  when 8
    return "Great week for {{fishName}} {{siteLeadIn}} {{siteName}} – conditions are right and the fish are biting."
  when 9
    return "Phenomenal {{fishName}} fishing out {{siteLeadIn}} {{siteName}} this week. Great time to go and catch a few {{fishName}}."
  when 10
    return "Excellent {{fishName}} action {{siteLeadIn}} {{siteName}} right now. It doesn't get better than this. Get out there now if you possibly can."
  else
    return "Nothing happening here this week."
  end
end


# Download USGS Data
##################################

task :download_usgs_data => :environment do
  puts 'download_usgs_data running...'

  sites = Site.where("is_active = TRUE AND usgs_site_id <> ''")
  sites.each do |site|
    dataJSON = fetchUSGSDataJSON site
    parseAndSaveUSGSData dataJSON, site.id
  end

  puts 'download_usgs_data done.'
end


def fetchUSGSDataJSON(site)
  require 'net/http'

  reportDataParameters = ReportDataParameter.where({'is_active' => true})
  usgsParameterCodes = reportDataParameters.pluck(:usgs_parameter_code)

  # Changed to just do one at a time, based on the input site usgs_site_id
  usgsSiteIds = [site.usgs_site_id]

  lookback_day = Date.today - Settings.usgs.lookback_days
  latest_report_data = ReportData.where("site_id = " + site.id.to_s + " AND datetime > '" + lookback_day.to_s + "'").order('datetime').last
  apiParameters = getUSGSAPIParameters( usgsSiteIds, usgsParameterCodes, latest_report_data )
  
  # This is a little ridiculous, but apparently necessary to do a GET with query params.
  #  See here: http://stackoverflow.com/questions/1252210/parametrized-get-request-in-ruby
  uri = URI.parse( Settings.usgs.apiBaseURL )
  http = Net::HTTP.new(uri.host, uri.port) 
  request = Net::HTTP::Get.new(uri.path) 
  request.set_form_data( apiParameters )
  request = Net::HTTP::Get.new( uri.path+ '?' + request.body ) 
  response = http.request(request)
  dataJSON = JSON.parse( response.body )

  return dataJSON
end


def getUSGSAPIParameters(usgsSiteIds, usgsParameterCodes, latest_report_data)
  apiParameters ||= {}
  apiParameters['period'] = getUSGSPeriod(latest_report_data)
  apiParameters['format'] = Settings.usgs.fetchFormat
  apiParameters['sites'] = usgsSiteIds.join(',')
  apiParameters['parameterCd'] = usgsParameterCodes.join(',')

  return apiParameters
end

def getUSGSPeriod(latest_report_data)

  lookback_days = Settings.usgs.lookback_days

  if !latest_report_data.blank?
    lookback_days = ( ( Date.today - latest_report_data.datetime.to_date ).numerator ) + 1
  end

  if lookback_days < 1
    lookback_days = 1
  elsif lookback_days > Settings.usgs.lookback_days
    lookback_days = Settings.usgs.lookback_days
  end
  period = 'P' + lookback_days.to_s + 'D'

  return period
end


def parseAndSaveUSGSData(usgsDataJSON, siteId)
  usgsDataJSON ||= {}
  usgsData = []
  timeSeriesSets = usgsDataJSON['value']['timeSeries']
  timeSeriesSets.each do |timeSeriesSet|
    sourceInfo = timeSeriesSet['sourceInfo']
    variable = timeSeriesSet['variable']
    values = timeSeriesSet['values']

    usgsParameterCode = variable['variableCode'][0]['value']
    reportDataParameter = ReportDataParameter.find_by usgs_parameter_code: usgsParameterCode
    reportDataParameterId = reportDataParameter.id

    valueSet = values[0]['value']
    valueSet.each do |value|
      usgsDatum = {}
      usgsDateTime = value['dateTime']
      usgsDatum['datetime'] = DateTime.parse( usgsDateTime )
      usgsDatum['value'] = value['value']
      usgsDatum['site_id'] = siteId
      usgsDatum['report_data_parameter_id'] = reportDataParameterId
      usgsData.append(usgsDatum)
    end
  end

  saveUSGSData usgsData

end

def saveUSGSData(usgsData)
  usgsData.each do |usgsDatum|
    findParams = {:site_id => usgsDatum['site_id'], :report_data_parameter_id => usgsDatum['report_data_parameter_id'], :datetime => usgsDatum['datetime']}
    reportData = ReportData.find_or_initialize_by(findParams)
    reportData.update(usgsDatum)
  end
end

=begin
{"name":"ns1:timeSeriesResponseType","declaredType":"org.cuahsi.waterml.TimeSeriesResponseType","scope":"javax.xml.bind.JAXBElement$GlobalScope","value":{"queryInfo":{"creationTime":null,"queryURL":"http://127.0.0.1:8080/nwis/iv/","criteria":{"locationParam":"[ALL:11342000]","variableParam":"[00065]","timeParam":null,"parameter":[],"methodCalled":null},"note":[{"value":"[ALL:11342000]","type":null,"href":null,"title":"filter:sites","show":null},{"value":"[mode=PERIOD, period=PT1H, modifiedSince=null]","type":null,"href":null,"title":"filter:timeRange","show":null},{"value":"methodIds=[ALL]","type":null,"href":null,"title":"filter:methodId","show":null},{"value":"2014-05-09T19:07:45.105Z","type":null,"href":null,"title":"requestDT","show":null},{"value":"33e27500-d7ad-11e3-9239-6cae8b663fb6","type":null,"href":null,"title":"requestId","show":null},{"value":"Provisional data are subject to revision. Go to http://waterdata.usgs.gov/nwis/help/?provisional for more information.","type":null,"href":null,"title":"disclaimer","show":null},{"value":"vaas01","type":null,"href":null,"title":"server","show":null}],"extension":null},"timeSeries":[{"sourceInfo":{"siteName":"SACRAMENTO R A DELTA CA","siteCode":[{"value":"11342000","network":"NWIS","siteID":null,"agencyCode":"USGS","agencyName":null,"default":null}],"timeZoneInfo":{"defaultTimeZone":{"zoneOffset":"-08:00","zoneAbbreviation":"PST"},"daylightSavingsTimeZone":{"zoneOffset":"-07:00","zoneAbbreviation":"PDT"},"siteUsesDaylightSavingsTime":true},"geoLocation":{"geogLocation":{"srs":"EPSG:4326","latitude":40.93959397,"longitude":-122.4172351},"localSiteXY":[]},"elevationM":null,"verticalDatum":null,"note":[],"extension":null,"altname":null,"siteType":[],"siteProperty":[{"value":"ST","type":null,"name":"siteTypeCd","uri":null},{"value":"18020005","type":null,"name":"hucCd","uri":null},{"value":"06","type":null,"name":"stateCd","uri":null},{"value":"06089","type":null,"name":"countyCd","uri":null}],"oid":null,"metadataTime":null},"variable":{"variableCode":[{"value":"00065","network":"NWIS","vocabulary":"NWIS:UnitValues","variableID":45807202,"default":true}],"variableName":"Gage height, ft","variableDescription":"Gage height, feet","valueType":"Derived Value","dataType":null,"generalCategory":null,"sampleMedium":null,"unit":{"unitName":null,"unitDescription":null,"unitType":null,"unitAbbreviation":"ft","unitCode":null,"unitID":null},"options":{"option":[{"value":null,"name":"Statistic","optionID":null,"optionCode":"00011"}]},"note":[],"related":null,"extension":null,"noDataValue":-999999.0,"timeScale":null,"speciation":null,"categories":null,"variableProperty":[],"oid":"45807202","metadataTime":null},"values":[{"value":[{"value":"4.51","dateTimeAccuracyCd":null,"qualifiers":["P"],"censorCode":null,"dateTime":"2014-05-09T11:15:00.000-07:00","timeOffset":null,"dateTimeUTC":null,"methodID":null,"sourceID":null,"accuracyStdDev":null,"sampleID":null,"methodCode":null,"sourceCode":null,"labSampleCode":null,"offsetValue":null,"offsetTypeID":null,"offsetTypeCode":null,"codedVocabulary":null,"codedVocabularyTerm":null,"qualityControlLevelCode":null,"metadataTime":null,"oid":null},{"value":"4.51","dateTimeAccuracyCd":null,"qualifiers":["P"],"censorCode":null,"dateTime":"2014-05-09T11:30:00.000-07:00","timeOffset":null,"dateTimeUTC":null,"methodID":null,"sourceID":null,"accuracyStdDev":null,"sampleID":null,"methodCode":null,"sourceCode":null,"labSampleCode":null,"offsetValue":null,"offsetTypeID":null,"offsetTypeCode":null,"codedVocabulary":null,"codedVocabularyTerm":null,"qualityControlLevelCode":null,"metadataTime":null,"oid":null}],"units":null,"qualifier":[{"qualifierCode":"P","qualifierDescription":"Provisional data subject to revision.","qualifierID":0,"network":"NWIS","vocabulary":"uv_rmk_cd","default":null}],"qualityControlLevel":[],"method":[{"methodCode":null,"methodDescription":"","methodLink":null,"methodID":3}],"source":[],"offset":[],"sample":[],"censorCode":[]}],"name":"USGS:11342000:00065:00011"}]},"nil":false,"globalScope":true,"typeSubstituted":false}
=end



# Download Weather Data
##################################
task :download_weather_data => :environment do
  puts 'download_weather_data running...'

  sites = Site.where("is_active = TRUE AND latitude <> '' AND longitude <> ''")
  sites.each do |site|
    is_forecast = false
    for lookbackDays in 1..Settings.weather_data.lookback_days
      date_to_lookup = Date.today - lookbackDays.days
      existing_site_precipitation_data = SitePrecipitationData.find_by({:site_id => site.id, :date => date_to_lookup, :is_forecast => false})
      if existing_site_precipitation_data.blank?
        data_JSON = fetchWeatherDataJSON site, is_forecast, date_to_lookup
        parseAndSaveWeatherData data_JSON, site.id, is_forecast, date_to_lookup
      end
    end
    is_forecast = true
    lookforward_date = Date.today + ( Settings.weather_data.lookforward_days.days - 1 )
    existing_site_precipitation_data = SitePrecipitationData.find_by({:site_id => site.id, :date => lookforward_date, :is_forecast => true})
    if existing_site_precipitation_data.blank?
      data_JSON = fetchWeatherDataJSON site, is_forecast, nil
      parseAndSaveWeatherData data_JSON, site.id, is_forecast, nil
    end
  end

  puts 'download_weather_data done.'
end

def fetchWeatherDataJSON(site, is_forecast, date_to_lookup)

  puts 'fetchWeatherDataJSON, site.id: ' + site.id.to_s + ', is_forecast: ' + is_forecast.to_s + ', date_to_lookup: ' + date_to_lookup.to_s
  return

  require 'net/http'

  weatherDataURL = buildWeatherDataURL(site, is_forecast, date_to_lookup)
  
  # This is a little ridiculous, but apparently necessary to do a GET with query params.
  #  See here: http://stackoverflow.com/questions/1252210/parametrized-get-request-in-ruby
  uri = URI.parse( weatherDataURL )
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Get.new(uri.path) 
  request = Net::HTTP::Get.new( uri.path )
  response = http.request(request)
  dataJSON = JSON.parse( response.body )

  return dataJSON
end

def buildWeatherDataURL( site, is_forecast, date_to_lookup )

  #http://api.wunderground.com/api/beb64e8d472df60b/history_20140502/geolookup/q/40.59182859772545,-122.3833179473877.json

  url = Settings.weather_data.base_url
  url += Settings.weather_data.api_key + '/'
  if is_forecast
    url += 'forecast10day/'
  else
    url += 'history_'
    url += date_to_lookup.strftime('%Y%m%d') + '/'
  end
  url += 'q/'
  url += site.latitude + ',' + site.longitude
  url += '.json'

  return url
end

def parseAndSaveWeatherData(dataJSON, site_id, is_forecast, history_date)
  parsed_weather_data = parseWeatherData(dataJSON, site_id, is_forecast, history_date)
  if parsed_weather_data.blank?
    return
  end
  saveWeatherData parsed_weather_data
end

def parseWeatherData(dataJSON, site_id, is_forecast, historyDate)

  if dataJSON.blank?
    return nil
  end

  weatherData = []

  value = 0.0
  date = nil
  if is_forecast

    if ( dataJSON['forecast'].blank? or dataJSON['forecast']['simpleforecast'].blank? or dataJSON['forecast']['simpleforecast']['forecastday'].blank? )
      return
    end

    dailyForecasts = dataJSON['forecast']['simpleforecast']['forecastday']
    dailyForecasts.each do |dailyForecast|
      if ( !dailyForecast['date'].blank? and !dailyForecast['date']['pretty'].blank? )
        date = Date.parse( dailyForecast['date']['pretty'] )
      else
        return nil
      end

      if ( !dailyForecast['qpf_allday'].blank? and !dailyForecast['qpf_allday']['in'].blank? and dailyForecast['qpf_allday']['in'] != 'null' )
        value = dailyForecast['qpf_allday']['in'].to_f
      else
        if ( !dailyForecast['qpf_day'].blank? and !dailyForecast['qpf_day']['in'].blank? and dailyForecast['qpf_day']['in'] != 'null' )
          value += dailyForecast['qpf_day']['in'].to_f
        end
        if ( !dailyForecast['qpf_night'].blank? and !dailyForecast['qpf_night']['in'].blank? and dailyForecast['qpf_night']['in'] != 'null' )
          value += dailyForecast['qpf_night']['in'].to_f
        end
      end

      weatherDatum = {
        'site_id' => site_id,
        'date' => date,
        'is_forecast' => is_forecast,
        'value' => value
      }
      weatherData.append weatherDatum
    end
  else
    date = historyDate
    if ( dataJSON['history'].blank? or dataJSON['history']['dailysummary'].blank? or dataJSON['history']['dailysummary'][0].blank? )
      return
    end
    dailySummary = dataJSON['history']['dailysummary'][0]
    if ( !dailySummary['precipi'].blank? and dailySummary['precipi'] != 'null' )
      value = dailySummary['precipi'].to_f
    end
    weatherDatum = {
      'site_id' => site_id,
      'date' => date,
      'is_forecast' => is_forecast,
      'value' => value
    }
    weatherData.append weatherDatum

  end

  return weatherData

end


def saveWeatherData(weatherData)
  weatherData.each do |weatherDatum|
    findParams = {:site_id => weatherDatum['site_id'], :value => weatherDatum['value'], :date => weatherDatum['date'], :is_forecast => weatherDatum['is_forecast']}
    weatherData = SitePrecipitationData.find_or_initialize_by(findParams)
    weatherData.update(weatherDatum)
  end
end


=begin
  


{
    "response": {
        "version": "0.1",
        "termsofService": "http://www.wunderground.com/weather/api/d/terms.html",
        "features": {
            "forecast10day": 1
        }
    },
    "forecast": {
        "txt_forecast": {
            "date": "4:31 PM PDT",
            "forecastday": [{
                "period": 0,
                "icon": "clear",
                "icon_url": "http://icons.wxug.com/i/c/k/clear.gif",
                "title": "Wednesday",
                "fcttext": "Mostly clear. Low near 60F. Winds light and variable.",
                "fcttext_metric": "Mostly clear. Low 15C. Winds light and variable.",
                "pop": "0"
            }, {
                "period": 1,
                "icon": "nt_clear",
                "icon_url": "http://icons.wxug.com/i/c/k/nt_clear.gif",
                "title": "Wednesday Night",
                "fcttext": "Mostly clear. Low near 60F. Winds light and variable.",
                "fcttext_metric": "Mostly clear. Low 15C. Winds light and variable.",
                "pop": "0"
            }, {
                "period": 2,
                "icon": "partlycloudy",
                "icon_url": "http://icons.wxug.com/i/c/k/partlycloudy.gif",
                "title": "Thursday",
                "fcttext": "Intervals of clouds and sunshine. High 96F. Winds SE at 5 to 10 mph.",
                "fcttext_metric": "Sunshine and clouds mixed. High 36C. Winds SE at 10 to 15 kph.",
                "pop": "0"
            }, {
                "period": 3,
                "icon": "nt_partlycloudy",
                "icon_url": "http://icons.wxug.com/i/c/k/nt_partlycloudy.gif",
                "title": "Thursday Night",
                "fcttext": "Partly to mostly cloudy. Low 57F. Winds WNW at 10 to 15 mph.",
                "fcttext_metric": "Partly to mostly cloudy. Low 14C. Winds WNW at 15 to 25 kph.",
                "pop": "0"
            }, {
                "period": 4,
                "icon": "partlycloudy",
                "icon_url": "http://icons.wxug.com/i/c/k/partlycloudy.gif",
                "title": "Friday",
                "fcttext": "Partly cloudy skies. High 93F. Winds WSW at 10 to 15 mph.",
                "fcttext_metric": "Partly cloudy skies. High 34C. Winds WSW at 15 to 25 kph.",
                "pop": "0"
            }, {
                "period": 5,
                "icon": "nt_partlycloudy",
                "icon_url": "http://icons.wxug.com/i/c/k/nt_partlycloudy.gif",
                "title": "Friday Night",
                "fcttext": "Clear to partly cloudy. Low 56F. Winds WNW at 10 to 20 mph.",
                "fcttext_metric": "Partly cloudy. Low around 13C. Winds WNW at 15 to 30 kph.",
                "pop": "0"
            }, {
                "period": 6,
                "icon": "clear",
                "icon_url": "http://icons.wxug.com/i/c/k/clear.gif",
                "title": "Saturday",
                "fcttext": "Sunny. High 86F. Winds WSW at 10 to 15 mph.",
                "fcttext_metric": "Mainly sunny. High 30C. Winds WSW at 15 to 25 kph.",
                "pop": "0"
            }, {
                "period": 7,
                "icon": "nt_clear",
                "icon_url": "http://icons.wxug.com/i/c/k/nt_clear.gif",
                "title": "Saturday Night",
                "fcttext": "Generally fair. Low 54F. Winds WNW at 10 to 15 mph.",
                "fcttext_metric": "Mostly clear skies. Low 12C. Winds WNW at 15 to 25 kph.",
                "pop": "0"
            }, {
                "period": 8,
                "icon": "clear",
                "icon_url": "http://icons.wxug.com/i/c/k/clear.gif",
                "title": "Sunday",
                "fcttext": "Abundant sunshine. High 78F. Winds WSW at 10 to 15 mph.",
                "fcttext_metric": "Mostly sunny. High 25C. Winds WSW at 15 to 25 kph.",
                "pop": "0"
            }, {
                "period": 9,
                "icon": "nt_clear",
                "icon_url": "http://icons.wxug.com/i/c/k/nt_clear.gif",
                "title": "Sunday Night",
                "fcttext": "Mostly clear skies. Low 51F. Winds WNW at 10 to 15 mph.",
                "fcttext_metric": "Mostly clear skies. Low 11C. Winds WNW at 15 to 25 kph.",
                "pop": "10"
            }, {
                "period": 10,
                "icon": "partlycloudy",
                "icon_url": "http://icons.wxug.com/i/c/k/partlycloudy.gif",
                "title": "Monday",
                "fcttext": "Partly cloudy skies. High around 75F. Winds W at 10 to 15 mph.",
                "fcttext_metric": "Partly cloudy. High near 24C. Winds W at 10 to 15 kph.",
                "pop": "10"
            }, {
                "period": 11,
                "icon": "nt_clear",
                "icon_url": "http://icons.wxug.com/i/c/k/nt_clear.gif",
                "title": "Monday Night",
                "fcttext": "Clear skies. Low around 50F. Winds NW at 10 to 15 mph.",
                "fcttext_metric": "Clear. Low near 10C. Winds NW at 10 to 15 kph.",
                "pop": "10"
            }, {
                "period": 12,
                "icon": "clear",
                "icon_url": "http://icons.wxug.com/i/c/k/clear.gif",
                "title": "Tuesday",
                "fcttext": "Sunny skies. High 83F. Winds N at 10 to 15 mph.",
                "fcttext_metric": "Mainly sunny. High 29C. Winds N at 10 to 15 kph.",
                "pop": "0"
            }, {
                "period": 13,
                "icon": "nt_clear",
                "icon_url": "http://icons.wxug.com/i/c/k/nt_clear.gif",
                "title": "Tuesday Night",
                "fcttext": "Clear skies. Low 54F. Winds NNW at 10 to 15 mph.",
                "fcttext_metric": "Clear skies. Low 12C. Winds NNW at 15 to 25 kph.",
                "pop": "0"
            }, {
                "period": 14,
                "icon": "clear",
                "icon_url": "http://icons.wxug.com/i/c/k/clear.gif",
                "title": "Wednesday",
                "fcttext": "Mainly sunny. High 88F. Winds N at 5 to 10 mph.",
                "fcttext_metric": "A mainly sunny sky. High 31C. Winds N at 10 to 15 kph.",
                "pop": "0"
            }, {
                "period": 15,
                "icon": "nt_clear",
                "icon_url": "http://icons.wxug.com/i/c/k/nt_clear.gif",
                "title": "Wednesday Night",
                "fcttext": "Mostly clear skies. Low 58F. Winds N at 5 to 10 mph.",
                "fcttext_metric": "Mostly clear skies. Low 14C. Winds N at 10 to 15 kph.",
                "pop": "0"
            }, {
                "period": 16,
                "icon": "clear",
                "icon_url": "http://icons.wxug.com/i/c/k/clear.gif",
                "title": "Thursday",
                "fcttext": "Sunny skies. High 93F. Winds N at 5 to 10 mph.",
                "fcttext_metric": "Sunny. High 34C. Winds N at 10 to 15 kph.",
                "pop": "0"
            }, {
                "period": 17,
                "icon": "nt_clear",
                "icon_url": "http://icons.wxug.com/i/c/k/nt_clear.gif",
                "title": "Thursday Night",
                "fcttext": "Mostly clear skies. Low around 60F. Winds NNW at 5 to 10 mph.",
                "fcttext_metric": "Mostly clear skies. Low near 16C. Winds NNW at 10 to 15 kph.",
                "pop": "0"
            }, {
                "period": 18,
                "icon": "clear",
                "icon_url": "http://icons.wxug.com/i/c/k/clear.gif",
                "title": "Friday",
                "fcttext": "Sunshine. High 94F. Winds NNW at 5 to 10 mph.",
                "fcttext_metric": "Mostly sunny skies. High 34C. Winds NNW at 10 to 15 kph.",
                "pop": "0"
            }, {
                "period": 19,
                "icon": "nt_partlycloudy",
                "icon_url": "http://icons.wxug.com/i/c/k/nt_partlycloudy.gif",
                "title": "Friday Night",
                "fcttext": "A few clouds from time to time. Low 58F. Winds NNW at 5 to 10 mph.",
                "fcttext_metric": "A few clouds from time to time. Low 14C. Winds NNW at 10 to 15 kph.",
                "pop": "10"
            }]
        },
        "simpleforecast": {
            "forecastday": [{
                "date": {
                    "epoch": "1400119200",
                    "pretty": "7:00 PM PDT on May 14, 2014",
                    "day": 14,
                    "month": 5,
                    "year": 2014,
                    "yday": 133,
                    "hour": 19,
                    "min": "00",
                    "sec": 0,
                    "isdst": "1",
                    "monthname": "May",
                    "monthname_short": "May",
                    "weekday_short": "Wed",
                    "weekday": "Wednesday",
                    "ampm": "PM",
                    "tz_short": "PDT",
                    "tz_long": "America/Los_Angeles"
                },
                "period": 1,
                "high": {
                    "fahrenheit": "92",
                    "celsius": "33"
                },
                "low": {
                    "fahrenheit": "60",
                    "celsius": "16"
                },
                "conditions": "Clear",
                "icon": "clear",
                "icon_url": "http://icons.wxug.com/i/c/k/clear.gif",
                "skyicon": "",
                "pop": 0,
                "qpf_allday": {
                    "in": null,
                    "mm": null
                },
                "qpf_day": {
                    "in": null,
                    "mm": null
                },
                "qpf_night": {
                    "in": 0.00,
                    "mm": 0
                },
                "snow_allday": {
                    "in": null,
                    "cm": null
                },
                "snow_day": {
                    "in": null,
                    "cm": null
                },
                "snow_night": {
                    "in": 0.0,
                    "cm": 0.0
                },
                "maxwind": {
                    "mph": 0,
                    "kph": 0,
                    "dir": "",
                    "degrees": 0
                },
                "avewind": {
                    "mph": 0,
                    "kph": 0,
                    "dir": "",
                    "degrees": 0
                },
                "avehumidity": 44,
                "maxhumidity": 0,
                "minhumidity": 0
            }, {
                "date": {
                    "epoch": "1400205600",
                    "pretty": "7:00 PM PDT on May 15, 2014",
                    "day": 15,
                    "month": 5,
                    "year": 2014,
                    "yday": 134,
                    "hour": 19,
                    "min": "00",
                    "sec": 0,
                    "isdst": "1",
                    "monthname": "May",
                    "monthname_short": "May",
                    "weekday_short": "Thu",
                    "weekday": "Thursday",
                    "ampm": "PM",
                    "tz_short": "PDT",
                    "tz_long": "America/Los_Angeles"
                },
                "period": 2,
                "high": {
                    "fahrenheit": "96",
                    "celsius": "36"
                },
                "low": {
                    "fahrenheit": "57",
                    "celsius": "14"
                },
                "conditions": "Partly Cloudy",
                "icon": "partlycloudy",
                "icon_url": "http://icons.wxug.com/i/c/k/partlycloudy.gif",
                "skyicon": "",
                "pop": 0,
                "qpf_allday": {
                    "in": null,
                    "mm": null
                },
                "qpf_day": {
                    "in": 0.00,
                    "mm": 0
                },
                "qpf_night": {
                    "in": 0.00,
                    "mm": 0
                },
                "snow_allday": {
                    "in": null,
                    "cm": null
                },
                "snow_day": {
                    "in": 0.0,
                    "cm": 0.0
                },
                "snow_night": {
                    "in": 0.0,
                    "cm": 0.0
                },
                "maxwind": {
                    "mph": 8,
                    "kph": 13,
                    "dir": "SE",
                    "degrees": 132
                },
                "avewind": {
                    "mph": 8,
                    "kph": 13,
                    "dir": "SE",
                    "degrees": 132
                },
                "avehumidity": 42,
                "maxhumidity": 0,
                "minhumidity": 0
            }, {
                "date": {
                    "epoch": "1400292000",
                    "pretty": "7:00 PM PDT on May 16, 2014",
                    "day": 16,
                    "month": 5,
                    "year": 2014,
                    "yday": 135,
                    "hour": 19,
                    "min": "00",
                    "sec": 0,
                    "isdst": "1",
                    "monthname": "May",
                    "monthname_short": "May",
                    "weekday_short": "Fri",
                    "weekday": "Friday",
                    "ampm": "PM",
                    "tz_short": "PDT",
                    "tz_long": "America/Los_Angeles"
                },
                "period": 3,
                "high": {
                    "fahrenheit": "93",
                    "celsius": "34"
                },
                "low": {
                    "fahrenheit": "56",
                    "celsius": "13"
                },
                "conditions": "Partly Cloudy",
                "icon": "partlycloudy",
                "icon_url": "http://icons.wxug.com/i/c/k/partlycloudy.gif",
                "skyicon": "",
                "pop": 0,
                "qpf_allday": {
                    "in": null,
                    "mm": null
                },
                "qpf_day": {
                    "in": 0.00,
                    "mm": 0
                },
                "qpf_night": {
                    "in": 0.00,
                    "mm": 0
                },
                "snow_allday": {
                    "in": null,
                    "cm": null
                },
                "snow_day": {
                    "in": 0.0,
                    "cm": 0.0
                },
                "snow_night": {
                    "in": 0.0,
                    "cm": 0.0
                },
                "maxwind": {
                    "mph": 10,
                    "kph": 16,
                    "dir": "WSW",
                    "degrees": 245
                },
                "avewind": {
                    "mph": 10,
                    "kph": 16,
                    "dir": "WSW",
                    "degrees": 245
                },
                "avehumidity": 44,
                "maxhumidity": 0,
                "minhumidity": 0
            }, {
                "date": {
                    "epoch": "1400378400",
                    "pretty": "7:00 PM PDT on May 17, 2014",
                    "day": 17,
                    "month": 5,
                    "year": 2014,
                    "yday": 136,
                    "hour": 19,
                    "min": "00",
                    "sec": 0,
                    "isdst": "1",
                    "monthname": "May",
                    "monthname_short": "May",
                    "weekday_short": "Sat",
                    "weekday": "Saturday",
                    "ampm": "PM",
                    "tz_short": "PDT",
                    "tz_long": "America/Los_Angeles"
                },
                "period": 4,
                "high": {
                    "fahrenheit": "86",
                    "celsius": "30"
                },
                "low": {
                    "fahrenheit": "54",
                    "celsius": "12"
                },
                "conditions": "Clear",
                "icon": "clear",
                "icon_url": "http://icons.wxug.com/i/c/k/clear.gif",
                "skyicon": "",
                "pop": 0,
                "qpf_allday": {
                    "in": null,
                    "mm": null
                },
                "qpf_day": {
                    "in": 0.00,
                    "mm": 0
                },
                "qpf_night": {
                    "in": 0.00,
                    "mm": 0
                },
                "snow_allday": {
                    "in": null,
                    "cm": null
                },
                "snow_day": {
                    "in": 0.0,
                    "cm": 0.0
                },
                "snow_night": {
                    "in": 0.0,
                    "cm": 0.0
                },
                "maxwind": {
                    "mph": 10,
                    "kph": 16,
                    "dir": "WSW",
                    "degrees": 257
                },
                "avewind": {
                    "mph": 10,
                    "kph": 16,
                    "dir": "WSW",
                    "degrees": 257
                },
                "avehumidity": 44,
                "maxhumidity": 0,
                "minhumidity": 0
            }, {
                "date": {
                    "epoch": "1400464800",
                    "pretty": "7:00 PM PDT on May 18, 2014",
                    "day": 18,
                    "month": 5,
                    "year": 2014,
                    "yday": 137,
                    "hour": 19,
                    "min": "00",
                    "sec": 0,
                    "isdst": "1",
                    "monthname": "May",
                    "monthname_short": "May",
                    "weekday_short": "Sun",
                    "weekday": "Sunday",
                    "ampm": "PM",
                    "tz_short": "PDT",
                    "tz_long": "America/Los_Angeles"
                },
                "period": 5,
                "high": {
                    "fahrenheit": "78",
                    "celsius": "26"
                },
                "low": {
                    "fahrenheit": "51",
                    "celsius": "11"
                },
                "conditions": "Clear",
                "icon": "clear",
                "icon_url": "http://icons.wxug.com/i/c/k/clear.gif",
                "skyicon": "",
                "pop": 0,
                "qpf_allday": {
                    "in": null,
                    "mm": null
                },
                "qpf_day": {
                    "in": 0.00,
                    "mm": 0
                },
                "qpf_night": {
                    "in": 0.00,
                    "mm": 0
                },
                "snow_allday": {
                    "in": null,
                    "cm": null
                },
                "snow_day": {
                    "in": 0.0,
                    "cm": 0.0
                },
                "snow_night": {
                    "in": 0.0,
                    "cm": 0.0
                },
                "maxwind": {
                    "mph": 11,
                    "kph": 18,
                    "dir": "WSW",
                    "degrees": 254
                },
                "avewind": {
                    "mph": 11,
                    "kph": 18,
                    "dir": "WSW",
                    "degrees": 254
                },
                "avehumidity": 52,
                "maxhumidity": 0,
                "minhumidity": 0
            }, {
                "date": {
                    "epoch": "1400551200",
                    "pretty": "7:00 PM PDT on May 19, 2014",
                    "day": 19,
                    "month": 5,
                    "year": 2014,
                    "yday": 138,
                    "hour": 19,
                    "min": "00",
                    "sec": 0,
                    "isdst": "1",
                    "monthname": "May",
                    "monthname_short": "May",
                    "weekday_short": "Mon",
                    "weekday": "Monday",
                    "ampm": "PM",
                    "tz_short": "PDT",
                    "tz_long": "America/Los_Angeles"
                },
                "period": 6,
                "high": {
                    "fahrenheit": "75",
                    "celsius": "24"
                },
                "low": {
                    "fahrenheit": "50",
                    "celsius": "10"
                },
                "conditions": "Partly Cloudy",
                "icon": "partlycloudy",
                "icon_url": "http://icons.wxug.com/i/c/k/partlycloudy.gif",
                "skyicon": "",
                "pop": 10,
                "qpf_allday": {
                    "in": null,
                    "mm": null
                },
                "qpf_day": {
                    "in": 0.00,
                    "mm": 0
                },
                "qpf_night": {
                    "in": 0.00,
                    "mm": 0
                },
                "snow_allday": {
                    "in": null,
                    "cm": null
                },
                "snow_day": {
                    "in": 0.0,
                    "cm": 0.0
                },
                "snow_night": {
                    "in": 0.0,
                    "cm": 0.0
                },
                "maxwind": {
                    "mph": 10,
                    "kph": 16,
                    "dir": "W",
                    "degrees": 272
                },
                "avewind": {
                    "mph": 10,
                    "kph": 16,
                    "dir": "W",
                    "degrees": 272
                },
                "avehumidity": 54,
                "maxhumidity": 0,
                "minhumidity": 0
            }, {
                "date": {
                    "epoch": "1400637600",
                    "pretty": "7:00 PM PDT on May 20, 2014",
                    "day": 20,
                    "month": 5,
                    "year": 2014,
                    "yday": 139,
                    "hour": 19,
                    "min": "00",
                    "sec": 0,
                    "isdst": "1",
                    "monthname": "May",
                    "monthname_short": "May",
                    "weekday_short": "Tue",
                    "weekday": "Tuesday",
                    "ampm": "PM",
                    "tz_short": "PDT",
                    "tz_long": "America/Los_Angeles"
                },
                "period": 7,
                "high": {
                    "fahrenheit": "83",
                    "celsius": "28"
                },
                "low": {
                    "fahrenheit": "54",
                    "celsius": "12"
                },
                "conditions": "Clear",
                "icon": "clear",
                "icon_url": "http://icons.wxug.com/i/c/k/clear.gif",
                "skyicon": "",
                "pop": 0,
                "qpf_allday": {
                    "in": null,
                    "mm": null
                },
                "qpf_day": {
                    "in": 0.00,
                    "mm": 0
                },
                "qpf_night": {
                    "in": 0.00,
                    "mm": 0
                },
                "snow_allday": {
                    "in": null,
                    "cm": null
                },
                "snow_day": {
                    "in": 0.0,
                    "cm": 0.0
                },
                "snow_night": {
                    "in": 0.0,
                    "cm": 0.0
                },
                "maxwind": {
                    "mph": 9,
                    "kph": 14,
                    "dir": "N",
                    "degrees": 354
                },
                "avewind": {
                    "mph": 9,
                    "kph": 14,
                    "dir": "N",
                    "degrees": 354
                },
                "avehumidity": 47,
                "maxhumidity": 0,
                "minhumidity": 0
            }, {
                "date": {
                    "epoch": "1400724000",
                    "pretty": "7:00 PM PDT on May 21, 2014",
                    "day": 21,
                    "month": 5,
                    "year": 2014,
                    "yday": 140,
                    "hour": 19,
                    "min": "00",
                    "sec": 0,
                    "isdst": "1",
                    "monthname": "May",
                    "monthname_short": "May",
                    "weekday_short": "Wed",
                    "weekday": "Wednesday",
                    "ampm": "PM",
                    "tz_short": "PDT",
                    "tz_long": "America/Los_Angeles"
                },
                "period": 8,
                "high": {
                    "fahrenheit": "88",
                    "celsius": "31"
                },
                "low": {
                    "fahrenheit": "58",
                    "celsius": "14"
                },
                "conditions": "Clear",
                "icon": "clear",
                "icon_url": "http://icons.wxug.com/i/c/k/clear.gif",
                "skyicon": "",
                "pop": 0,
                "qpf_allday": {
                    "in": null,
                    "mm": null
                },
                "qpf_day": {
                    "in": 0.00,
                    "mm": 0
                },
                "qpf_night": {
                    "in": 0.00,
                    "mm": 0
                },
                "snow_allday": {
                    "in": null,
                    "cm": null
                },
                "snow_day": {
                    "in": 0.0,
                    "cm": 0.0
                },
                "snow_night": {
                    "in": 0.0,
                    "cm": 0.0
                },
                "maxwind": {
                    "mph": 9,
                    "kph": 14,
                    "dir": "N",
                    "degrees": 3
                },
                "avewind": {
                    "mph": 9,
                    "kph": 14,
                    "dir": "N",
                    "degrees": 3
                },
                "avehumidity": 44,
                "maxhumidity": 0,
                "minhumidity": 0
            }, {
                "date": {
                    "epoch": "1400810400",
                    "pretty": "7:00 PM PDT on May 22, 2014",
                    "day": 22,
                    "month": 5,
                    "year": 2014,
                    "yday": 141,
                    "hour": 19,
                    "min": "00",
                    "sec": 0,
                    "isdst": "1",
                    "monthname": "May",
                    "monthname_short": "May",
                    "weekday_short": "Thu",
                    "weekday": "Thursday",
                    "ampm": "PM",
                    "tz_short": "PDT",
                    "tz_long": "America/Los_Angeles"
                },
                "period": 9,
                "high": {
                    "fahrenheit": "93",
                    "celsius": "34"
                },
                "low": {
                    "fahrenheit": "60",
                    "celsius": "16"
                },
                "conditions": "Clear",
                "icon": "clear",
                "icon_url": "http://icons.wxug.com/i/c/k/clear.gif",
                "skyicon": "",
                "pop": 0,
                "qpf_allday": {
                    "in": null,
                    "mm": null
                },
                "qpf_day": {
                    "in": 0.00,
                    "mm": 0
                },
                "qpf_night": {
                    "in": 0.00,
                    "mm": 0
                },
                "snow_allday": {
                    "in": null,
                    "cm": null
                },
                "snow_day": {
                    "in": 0.0,
                    "cm": 0.0
                },
                "snow_night": {
                    "in": 0.0,
                    "cm": 0.0
                },
                "maxwind": {
                    "mph": 8,
                    "kph": 13,
                    "dir": "N",
                    "degrees": 2
                },
                "avewind": {
                    "mph": 8,
                    "kph": 13,
                    "dir": "N",
                    "degrees": 2
                },
                "avehumidity": 50,
                "maxhumidity": 0,
                "minhumidity": 0
            }, {
                "date": {
                    "epoch": "1400896800",
                    "pretty": "7:00 PM PDT on May 23, 2014",
                    "day": 23,
                    "month": 5,
                    "year": 2014,
                    "yday": 142,
                    "hour": 19,
                    "min": "00",
                    "sec": 0,
                    "isdst": "1",
                    "monthname": "May",
                    "monthname_short": "May",
                    "weekday_short": "Fri",
                    "weekday": "Friday",
                    "ampm": "PM",
                    "tz_short": "PDT",
                    "tz_long": "America/Los_Angeles"
                },
                "period": 10,
                "high": {
                    "fahrenheit": "94",
                    "celsius": "34"
                },
                "low": {
                    "fahrenheit": "58",
                    "celsius": "14"
                },
                "conditions": "Clear",
                "icon": "clear",
                "icon_url": "http://icons.wxug.com/i/c/k/clear.gif",
                "skyicon": "",
                "pop": 0,
                "qpf_allday": {
                    "in": null,
                    "mm": null
                },
                "qpf_day": {
                    "in": 0.00,
                    "mm": 0
                },
                "qpf_night": {
                    "in": 0.00,
                    "mm": 0
                },
                "snow_allday": {
                    "in": null,
                    "cm": null
                },
                "snow_day": {
                    "in": 0.0,
                    "cm": 0.0
                },
                "snow_night": {
                    "in": 0.0,
                    "cm": 0.0
                },
                "maxwind": {
                    "mph": 8,
                    "kph": 13,
                    "dir": "NNW",
                    "degrees": 327
                },
                "avewind": {
                    "mph": 8,
                    "kph": 13,
                    "dir": "NNW",
                    "degrees": 327
                },
                "avehumidity": 47,
                "maxhumidity": 0,
                "minhumidity": 0
            }]
        }
    }
}


weatherData = []
for location in locations:
  
  today = date.today()

  daysInThePast = 1
  while ( daysInThePast <= daysToLookBack ):

    locationId = location['locationId']
    latitude = location['latitude']
    longitude = location['longitude']

    dateInThePast = today - timedelta(daysInThePast)
    url = buildURL( dateInThePast, latitude, longitude )
    print( url )

    apiResponse = urllib2.urlopen(url)
    apiResponseString = apiResponse.read()
    apiResponseJSON = json.loads(apiResponseString)

    if ( not apiResponseJSON ) \
      or ( not apiResponseJSON['history'] ) \
      or ( not apiResponseJSON['history']['dailysummary'] ) \
      or ( not apiResponseJSON['history']['dailysummary'][0] ):
      break

    dailySummary = apiResponseJSON['history']['dailysummary'][0]

    #pprint(dailySummary)

    try:
      precipitationInches = float(dailySummary['precipi'])
    except ValueError:
      precipitationInches = 0.0

    weatherDatum = {
        'locationId': locationId
      , 'date': dateInThePast.strftime('%Y-%m-%d')
      , 'precipitationInches': precipitationInches
    }
    weatherData.append( weatherDatum )

    daysInThePast = daysInThePast + 1


count = 0
  
=end