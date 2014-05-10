task :calculate_fish_scores => :environment do
  puts 'calculate_fish_scores running...'
  siteFishInfos = SiteFishInfo.where(is_active: true)
  
  siteFishInfos.each do |sfi|
    next if !sfi.fish.is_active
    today = Date.today
    thisMonthIndex = ( today.month - 1 )
    value = (sfi['max_score'].to_f / Settings.max_fish_score) * sfi['month_value_' + thisMonthIndex.to_s].to_f

    findParams = {:site_id => sfi.site_id, :fish_id => sfi.fish_id, :date => Date.today}
    fishScoreData = {:site_id => sfi.site_id, :fish_id => sfi.fish_id, :date => Date.today, :value => value }
    fishScore = FishScore.find_or_initialize_by(findParams)
    fishScore.update(fishScoreData)
  end
  puts 'calculate_fish_scores done.'
end


task :download_usgs_data => :environment do
  puts 'download_usgs_data running...'

  usgsDataJSON = fetchUSGSDataJSON()
  parseAndSaveUSGSData usgsDataJSON

  puts 'download_usgs_data done.'
end


def fetchUSGSDataJSON
  require 'net/http'

  sites = Site.where("is_active = TRUE AND usgs_site_id <> ''")
  usgsSiteIds = sites.pluck(:usgs_site_id)

  reportDataParameters = ReportDataParameter.where({'is_active' => true})
  usgsParameterCodes = reportDataParameters.pluck(:usgs_parameter_code)

  apiParameters = getUSGSAPIParameters( usgsSiteIds, usgsParameterCodes )
  
  # This is a little ridiculous, but apparently necessary to do a GET with query params.
  #  See here: http://stackoverflow.com/questions/1252210/parametrized-get-request-in-ruby
  uri = URI.parse( Settings.usgs.apiBaseURL )
  http = Net::HTTP.new(uri.host, uri.port) 
  request = Net::HTTP::Get.new(uri.path) 
  request.set_form_data( apiParameters )
  request = Net::HTTP::Get.new( uri.path+ '?' + request.body ) 
  response = http.request(request)
  usgsDataJSON = JSON.parse( response.body )

  return usgsDataJSON
end


def getUSGSAPIParameters(usgsSiteIds, usgsParameterCodes)
  apiParameters ||= {}
  apiParameters['period'] = Settings.usgs.defaultFetchPeriod
  apiParameters['format'] = Settings.usgs.fetchFormat
  apiParameters['sites'] = usgsSiteIds.join(',')
  apiParameters['parameterCd'] = usgsParameterCodes.join(',')

  return apiParameters
end


def parseAndSaveUSGSData(usgsDataJSON)
  usgsDataJSON ||= {}
  usgsData = []
  timeSeriesSets = usgsDataJSON['value']['timeSeries']
  timeSeriesSets.each do |timeSeriesSet|
    sourceInfo = timeSeriesSet['sourceInfo']
    variable = timeSeriesSet['variable']
    values = timeSeriesSet['values']

    usgsSiteId = sourceInfo['siteCode'][0]['value']
    usgsParameterCode = variable['variableCode'][0]['value']

    site = Site.find_by usgs_site_id: usgsSiteId
    siteId = site.id
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