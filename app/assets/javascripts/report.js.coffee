# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

#= require jsapi.min
#= require readmore.min

window.FK || = {}

window.FK.init = () ->
  google.load 'visualization', '1.0', {'packages':['corechart']}
  window.FK.setOverlayImages()
  window.FK.initializeSiteMap()
  window.FK.setReadMore()


window.FK.setOverlayImages = () ->
  $('.overlayImage').each (index, overlayImageDiv) ->
    overlayImage = $(overlayImageDiv)
    image = overlayImage.attr 'data-image'
    currentBackgroundImage = overlayImage.css 'background-image'
    newBackgroundImage = currentBackgroundImage + ", url('" + image + "')"
    overlayImage.css 'background-image', newBackgroundImage


window.FK.setReadMore = () ->
  $('#siteDescription').readmore
    speed: 300
    maxHeight: 510
    moreLink: '<div class="btn btn-default">read more</div>'
    lessLink: '<div class="btn btn-default">close</div>'


window.FK.initializeSiteMap = () ->

  mapOptions =
    mapTypeId: google.maps.MapTypeId.TERRAIN
    streetViewControl: false
    #zoom: window.FK.mapZoomLevel
    #center: new google.maps.LatLng window.FK.mapCenterLatitude, window.FK.mapCenterLongitude

  map = new google.maps.Map document.getElementById('siteMap'), mapOptions
  bounds = new google.maps.LatLngBounds()

  if siteIsLake and ( mapLineData.length > 0 )
    # Construct the polygon.
    polygon = new google.maps.Polygon
      paths: mapLineData[0]
      strokeColor: '#26569E'
      strokeOpacity: 0.8
      strokeWeight: 0
      fillColor: '#26569E'
      fillOpacity: 0.8
    for mapPoint in mapLineData[0]
        bounds.extend mapPoint

    polygon.setMap map

  else #stream
    for lineData in mapLineData
      polyLine = new google.maps.Polyline
        path: lineData
        geodesic: true
        strokeColor: '#26569E'
        strokeOpacity: 1.0
        strokeWeight: 4

      polyLine.setMap map
      for mapPoint in lineData
        bounds.extend mapPoint

  map.fitBounds bounds


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
      ticks: window.FK.usgsChartDataTicks
      gridlines:
          color: 'transparent'
      baselineColor: '#aaaaaa'
    vAxis:
      gridlines:
          color: 'transparent'
      baselineColor: '#aaaaaa'
      minValue: 0
    lineWidth: 6
    colors: ['#2a5d5d']
    fontName: 'Lato'
    fontSize: '14'
      
  chartElement = document.getElementById 'usgsDataChart'
  chart = new google.visualization.LineChart chartElement
  chart.draw data, options


window.FK.drawWeatherDataChart = () ->

  data = google.visualization.arrayToDataTable window.FK.weatherChartData

  options =
    #title: window.FK.weatherChartTitle
    legend:
      position: 'none'
    backgroundColor:
      fill:'transparent'
    hAxis: 
      ticks: window.FK.weatherChartDataTicks
      gridlines:
          color: 'transparent'
      baselineColor: '#aaaaaa'
    vAxis:
      gridlines:
          color: 'transparent'
      baselineColor: '#aaaaaa'
      minValue: 0
    lineWidth: 6
    colors: ['#2a5d5d']
    fontName: 'Lato'
    fontSize: '14'


  chart = new google.visualization.ColumnChart document.getElementById 'weatherDataChart'
  chart.draw data, options