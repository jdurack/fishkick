# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

unless window.FishKick
  window.FishKick = {}

window.FishKick.setOverlayImages = () ->
  $('.overlayImage').each (index, overlayImageDiv) ->
    overlayImage = $(overlayImageDiv)
    image = overlayImage.attr 'data-image'
    currentBackgroundImage = overlayImage.css 'background-image'
    newBackgroundImage = currentBackgroundImage + ", url('" + image + "')"
    overlayImage.css 'background-image', newBackgroundImage

$(document).on 'page:change', window.FishKick.setOverlayImages

window.FishKick.initializeMap = () ->

  mapOptions =
    zoom: mapZoomLevel
    center: new google.maps.LatLng(mapCenterLatitude, mapCenterLongitude)
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
 


window.FishKick.drawUSGSDataChart = () ->

  data = google.visualization.arrayToDataTable window.FishKick.usgsChartData
    
  options =
    title: window.FishKick.usgsChartTitle
    curveType: 'function'
    legend:
      position: 'bottom'

  chartElement = document.getElementById 'usgsDataChart'
  chart = new google.visualization.LineChart chartElement
  chart.draw data, options

window.FishKick.drawWeatherDataChart = () ->

  data = google.visualization.arrayToDataTable window.FishKick.weatherChartData

  options =
    title: window.FishKick.weatherChartTitle
    hAxis:
      title: ''
      titleTextStyle:
        color: 'red'

  chart = new google.visualization.ColumnChart document.getElementById('weatherDataChart')
  chart.draw(data, options);