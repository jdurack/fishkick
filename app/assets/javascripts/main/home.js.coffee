
window.FK || = {}


window.FK.init = () ->
  window.FK.setMainOverlayImage()


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
  

window.FK.drawSites = () ->
  
  bounds = new google.maps.LatLngBounds()
  for site in window.FK.sites

    if site.isLake 
      if ( site.mapLineData.length > 0 )
        polygon = new google.maps.Polygon
          paths: site.mapLineData[0]
          strokeColor: '#26569E'
          strokeOpacity: 0.8
          strokeWeight: 0
          fillColor: '#26569E'
          fillOpacity: 0.8

        polygon.setMap window.FK.mainMap
        for mapPoint in site.mapLineData[0]
          bounds.extend mapPoint

    else # river
      for lineData in site.mapLineData
        polyLine = new google.maps.Polyline
          path: lineData
          geodesic: true
          strokeColor: '#26569E'
          strokeOpacity: 1.0
          strokeWeight: 4

        polyLine.setMap window.FK.mainMap
        for mapPoint in lineData
          bounds.extend mapPoint

    window.FK.mainMap.fitBounds bounds

    score = window.FK.getTopScoreForSite site
    marker = new google.maps.Marker
      position: site.center
      map: window.FK.mainMap
      icon: window.FK.getMapMarkerFromScore score
      opacity: .9
    

window.FK.getMapMarkerFromScore = (score) ->
  base = '/assets/fishScores/'
  path = base + score + '.svg'
  path


window.FK.getTopScoreForSite = (site) ->
  #TODO: filter by fish
  topScore = 0
  for fishScore in site.fishScores
    if fishScore.score > topScore
      topScore = fishScore.score

  topScore


window.FK.zoomToFit = () ->

###
  map = scope.googleMap.getGMap()
  bounds = new google.maps.LatLngBounds()

  
  for topScore in scope.topScores
    if (! scope.fishSelect) or topScore.fishId is scope.fishSelect
      mapPoint = new google.maps.LatLng topScore['siteLatitude'], topScore['siteLongitude']
      bounds.extend mapPoint
  map.fitBounds bounds

  if map.getZoom() < scope.minZoom
    map.setZoom scope.minZoom
  if map.getZoom() > scope.maxZoom
    map.setZoom scope.maxZoom
###