
window.FK || = {}
window.FK.selectedFishId = null
window.FK.selectedSiteId = null
window.FK.mapMarkers = []
window.FK.waterBodyElements = {}
window.FK.waterBodyIsLake = {}

window.FK.lakeStrokeWeight = 0
window.FK.lakeStrokeWeightHover = 10
window.FK.riverStrokeWeight = 5
window.FK.riverStrokeWeightHover = 9
window.FK.waterBodyOpacity = .7
window.FK.waterBodyOpacityHover = .8
window.FK.markerOpacity = .9

window.FK.init = () ->
  window.FK.setMainOverlayImage()
  
  $('#mapInfoWindowClose').click () ->
    $('#mapInfoWindow').hide()
    window.FK.setHoverState false, window.FK.waterBodyElements[window.FK.selectedSiteId], window.FK.waterBodyIsLake[window.FK.selectedSiteId]
    window.FK.selectedSiteId = null

  $('.mainMapFishImageAndLabelBox').click window.FK.fishSelectClick


window.FK.setMainOverlayImage = () ->
  $('.overlayImage').each (index, overlayImageDiv) ->
    overlayImage = $(overlayImageDiv)
    image = overlayImage.attr 'data-image'
    currentBackgroundImage = overlayImage.css 'background-image'
    newBackgroundImage = currentBackgroundImage + ", url('" + image + "')"
    overlayImage.css 'background-image', newBackgroundImage


window.FK.initializeMap = () ->

  mapOptions =
    mapTypeId: google.maps.MapTypeId.TERRAIN
    streetViewControl: false
    center:
      lat: 40.8688
      lng: -123.2295
    zoom: 8

  window.FK.mainMap = new google.maps.Map document.getElementById('mainMap'), mapOptions
  

window.FK.sortSiteFishScores = () ->
  for site in window.FK.sites
    site.fishScores.sort (a, b) ->
      if ( a.score < b.score )
        return -1
      if ( a.score > b.score )
        return 1
      return 0


window.FK.drawSites = () ->
  
  bounds = new google.maps.LatLngBounds()
  for site in window.FK.sites
    window.FK.drawSite site, bounds

  window.FK.mainMap.fitBounds bounds
  window.FK.redrawMarkers()


window.FK.drawSite = (site, bounds) ->
  if site.isLake 
    if ( site.mapLineData.length > 0 )
      polygon = new google.maps.Polygon
        paths: site.mapLineData[0]
        strokeColor: '#26569E'
        strokeOpacity: window.FK.waterBodyOpacity
        strokeWeight: window.FK.lakeStrokeWeight
        fillColor: '#26569E'
        fillOpacity: window.FK.waterBodyOpacity

      polygon.setMap window.FK.mainMap
      window.FK.addInfoWindow site, polygon
      window.FK.addWaterBodyHoverStyling site.id, [polygon], true
      for mapPoint in site.mapLineData[0]
        bounds.extend mapPoint

  else # river
    polyLines = []
    for lineData in site.mapLineData
      polyLine = new google.maps.Polyline
        path: lineData
        geodesic: true
        strokeColor: '#26569E'
        strokeOpacity: window.FK.waterBodyOpacity
        strokeWeight: window.FK.riverStrokeWeight

      polyLines.push polyLine

      polyLine.setMap window.FK.mainMap
      window.FK.addInfoWindow site, polyLine
      for mapPoint in lineData
        bounds.extend mapPoint    
    window.FK.addWaterBodyHoverStyling site.id, polyLines


window.FK.addWaterBodyHoverStyling = (siteId, mapElements, isLake) ->

  window.FK.waterBodyElements[siteId] = mapElements
  window.FK.waterBodyIsLake[siteId] = isLake

  for mapElement in mapElements
    google.maps.event.addListener mapElement, 'mouseover', () ->
      window.FK.setHoverState true, mapElements, isLake


    google.maps.event.addListener mapElement, 'mouseout', () ->
      unless window.FK.selectedSiteId is siteId
        window.FK.setHoverState false, mapElements, isLake
        

window.FK.setHoverState = (isHover, mapElements, isLake) ->

  strokeWeight = window.FK.riverStrokeWeight
  strokeWeightHover = window.FK.riverStrokeWeightHover
  if isLake
    strokeWeight = window.FK.lakeStrokeWeight
    strokeWeightHover = window.FK.lakeStrokeWeightHover

  for mapElement in mapElements
    if isHover
      mapElement.setOptions
        strokeWeight: strokeWeightHover
        strokeOpacity: window.FK.waterBodyOpacityHover
        fillOpacity: window.FK.waterBodyOpacityHover
    else
      mapElement.setOptions
        strokeWeight: strokeWeight
        strokeOpacity: window.FK.waterBodyOpacity
        fillOpacity: window.FK.waterBodyOpacity
    

window.FK.redrawMarkers = () ->
  for marker in window.FK.mapMarkers
    marker.setMap null
  window.FK.mapMarkers.length = 0

  for site in window.FK.sites
    score = window.FK.getTopScoreForSite site
    if score isnt null
      marker = new google.maps.Marker
        position: site.center
        map: window.FK.mainMap
        icon: window.FK.getMapMarkerFromScore score
        opacity: window.FK.markerOpacity


      window.FK.addMarkerHoverStyling marker, site.id

      window.FK.addInfoWindow site, marker
      window.FK.mapMarkers.push marker


window.FK.addMarkerHoverStyling = (marker, siteId) ->
  google.maps.event.addListener marker, 'mouseover', () ->
    window.FK.setHoverState true, window.FK.waterBodyElements[siteId], window.FK.waterBodyIsLake[siteId]

  google.maps.event.addListener marker, 'mouseout', () ->
    unless window.FK.selectedSiteId is siteId
      window.FK.setHoverState false, window.FK.waterBodyElements[siteId], window.FK.waterBodyIsLake[siteId]



window.FK.addInfoWindow = (site, marker) ->
  google.maps.event.addListener marker, 'click', () ->
    if window.FK.selectedSiteId and window.FK.selectedSiteId isnt site.id
      window.FK.setHoverState false, window.FK.waterBodyElements[window.FK.selectedSiteId], window.FK.waterBodyIsLake[window.FK.selectedSiteId]
    window.FK.selectedSiteId = site.id
    window.FK.setInfoWindowContent site
    $('#mapInfoWindow').show()


window.FK.setInfoWindowContent = (site) ->
  $('#mapInfoWindowTitle').html site.name
  $('#mapInfoWindowTitle').click () ->
    window.location = '/fishing-report/' + site.nameURL

  if site.mostRecentUSGSDataValue
    dataValue = site.mostRecentUSGSDataValue
    if dataValue.indexOf('.') isnt -1
      dataValue = dataValue.substring 0, dataValue.indexOf('.')
    usgsDataValueContent = site.usgsDataParameterLabel + ': ' + dataValue + ' ' + site.usgsDataParameterUnits
    $('#mapInfoWindowUSGSData').html usgsDataValueContent
    $('#mapInfoWindowUSGSData').show()
  else
    $('#mapInfoWindowUSGSData').hide()

  $("#mapInfoWindowFishScores").empty()
  for fishScore in site.fishScores
    $("#mainMapFishScore").tmpl(fishScore).prependTo("#mapInfoWindowFishScores")

  $('#mapInfoWindowReportButton').attr('href','/fishing-report/' + site.nameURL);
    

window.FK.getMapMarkerFromScore = (score) ->
  base = '/images/fishScores/'
  path = base + score + '.svg'
  path


window.FK.getTopScoreForSite = (site) ->
  topScore = null
  for fishScore in site.fishScores
    if ( window.FK.selectedFishId is null ) or ( fishScore.fishId is window.FK.selectedFishId )
      if ( topScore is null ) or ( fishScore.score > topScore )
        topScore = fishScore.score

  topScore


window.FK.selectFish = (fishId) ->
  window.FK.selectedFishId = fishId
  window.FK.redrawMarkers()


window.FK.fishSelectClick = (event) ->
  element = $(event.target).closest('.mainMapFishImageAndLabelBox')[0]
  idSelector = 'fishSelect_'
  fishId = element.id.substring idSelector.length

  selectedClass = 'selected'

  if window.FK.selectedFishId is fishId
    #unselecting a single one (and selecting all instead)
    $('.mainMapFishImageAndLabelBox').addClass selectedClass
    window.FK.selectFish null
  else
    $('.mainMapFishImageAndLabelBox').removeClass selectedClass
    $(element).addClass selectedClass
    window.FK.selectFish fishId