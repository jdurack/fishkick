
window.FK || = {}


window.FK.init = () ->
  window.FK.setMainOverlayImage()
  $('#mapInfoWindowClose').click () ->
    $('#mapInfoWindow').hide()


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
        window.FK.addInfoWindow site, polygon
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
        window.FK.addInfoWindow site, polyLine
        for mapPoint in lineData
          bounds.extend mapPoint

    window.FK.mainMap.fitBounds bounds

    score = window.FK.getTopScoreForSite site
    marker = new google.maps.Marker
      position: site.center
      map: window.FK.mainMap
      icon: window.FK.getMapMarkerFromScore score
      opacity: .9

    window.FK.addInfoWindow site, marker


window.FK.addInfoWindow = (site, marker) ->
  google.maps.event.addListener marker, 'click', () ->
    window.FK.setInfoWindowContent site
    $('#mapInfoWindow').show()


window.FK.setInfoWindowContent = (site) ->
  $('#mapInfoWindowTitle').html site.name
  $('#mapInfoWindowTitle').click () ->
    window.location = '/fishing-report/' + site.nameURL

  $("#mapInfoWindowFishScores").empty()
  for fishScore in site.fishScores
    $("#mainMapFishScore").tmpl(fishScore).prependTo("#mapInfoWindowFishScores")

  $('#mapInfoWindowReportButton').attr('href','/fishing-report/' + site.nameURL);
    

window.FK.getMapMarkerFromScore = (score) ->
  base = '/images/fishScores/'
  path = base + score + '.svg'
  path


window.FK.getTopScoreForSite = (site) ->
  #TODO: filter by fish
  topScore = 0
  for fishScore in site.fishScores
    if fishScore.score > topScore
      topScore = fishScore.score

  topScore