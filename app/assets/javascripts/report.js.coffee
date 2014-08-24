# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

#= require google-maps-api.min
#= require jsapi.min

console.log 'report.js running'

window.FK || = {}


window.FK.init = () ->

  console.log 'init running (google viz load)'

  google.load 'visualization', '1.0', {'packages':['corechart']}
  window.FK.setOverlayImages()
  window.FK.initializeSiteMap()


window.FK.setOverlayImages = () ->
  $('.overlayImage').each (index, overlayImageDiv) ->
    overlayImage = $(overlayImageDiv)
    image = overlayImage.attr 'data-image'
    currentBackgroundImage = overlayImage.css 'background-image'
    newBackgroundImage = currentBackgroundImage + ", url('" + image + "')"
    overlayImage.css 'background-image', newBackgroundImage


window.FK.initializeSiteMap = () ->

  mapOptions =
    zoom: window.FK.mapZoomLevel
    center: new google.maps.LatLng window.FK.mapCenterLatitude, window.FK.mapCenterLongitude
    mapTypeId: google.maps.MapTypeId.TERRAIN

  map = new google.maps.Map document.getElementById('siteMap'), mapOptions

  if siteIsLake and ( mapLineData.length > 0 )
    # Construct the polygon.
    polygon = new google.maps.Polygon
      paths: mapLineData[0]
      strokeColor: '#0000BB'
      strokeOpacity: 0.8
      strokeWeight: 0
      fillColor: '#0000BB'
      fillOpacity: 0.8

    polygon.setMap map

  else #stream
    for lineData in mapLineData
      polyLine = new google.maps.Polyline
        path: lineData
        geodesic: true
        strokeColor: '#0000BB'
        strokeOpacity: 1.0
        strokeWeight: 4

      polyLine.setMap map


window.FK.drawUSGSDataChart = () ->

  data = google.visualization.arrayToDataTable window.FK.usgsChartData
    
  options =
    #title: window.FK.usgsChartTitle
    curveType: 'function'
    legend:
      position: 'none'
    backgroundColor:
      fill:'transparent'
    hAxis:
      slantedText: false
      maxTextLines: 1
      minTextSpacing: 40

  chartElement = document.getElementById 'usgsDataChart'
  chart = new google.visualization.LineChart chartElement
  chart.draw data, options


window.FK.drawWeatherDataChart = () ->

  data = google.visualization.arrayToDataTable window.FK.weatherChartData

  options =
    title: window.FK.weatherChartTitle
    hAxis:
      title: ''
      titleTextStyle:
        color: 'red'
    backgroundColor:
      fill:'transparent'

  chart = new google.visualization.ColumnChart document.getElementById 'weatherDataChart'
  chart.draw data, options


window.FK.init()