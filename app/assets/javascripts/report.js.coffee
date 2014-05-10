# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

unless window.FishKick
  window.FishKick = {}

window.FishKick.initializeMap = () ->

  mapOptions =
    zoom: mapZoomLevel
    center: new google.maps.LatLng(mapCenterLatitude, mapCenterLongitude)
    mapTypeId: google.maps.MapTypeId.TERRAIN

  map = new google.maps.Map document.getElementById('siteMap'), mapOptions

  # Construct the polygon.
  siteMap = new google.maps.Polygon
    paths: mapPolygonPoints
    strokeColor: '#0000BB'
    strokeOpacity: 0.8
    strokeWeight: 0
    fillColor: '#0000BB'
    fillOpacity: 0.8

  siteMap.setMap map


window.FishKick.drawReportDataChart = () ->

  data = google.visualization.arrayToDataTable window.FishKick.chartData
    
  options =
    title: window.FishKick.chartTitle
    curveType: 'function'
    legend:
      position: 'bottom'

  chartElement = document.getElementById 'reportDataChart'
  chart = new google.visualization.LineChart chartElement
  chart.draw data, options