# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

unless window.FishKick
  window.FishKick = {}

# The following example creates complex markers to indicate beaches near
# Sydney, NSW, Australia. Note that the anchor is set to
# (0,32) to correspond to the base of the flagpole.

window.FishKick.initializeMainMap = () ->
  mapOptions =
    zoom: window.FishKick.mainMapZoom
    center: new google.maps.LatLng window.FishKick.mainMapCenter['latitude'], window.FishKick.mainMapCenter['longitude']
  mapElement = document.getElementById 'mainMap'
  map = new google.maps.Map mapElement, mapOptions
  window.FishKick.setMainMapMarkers map, window.FishKick.mainMapMarkers


window.FishKick.setMainMapMarkers = (map, markersInfo) ->

  # Add markers to the map

  # Marker sizes are expressed as a Size of X,Y
  # where the origin of the image (0,0) is located
  # in the top left of the image.

  # Origins, anchor positions and coordinates of the marker
  # increase in the X direction to the right and in
  # the Y direction down.
  image =
    url: '/assets/beachflag.png'
    size: new google.maps.Size(20, 32) # This marker is 20 pixels wide by 32 pixels tall.
    origin: new google.maps.Point(0,0) # The origin for this image is 0,0.
    anchor: new google.maps.Point(0, 32) # The anchor for this image is the base of the flagpole at 0,32.

  # Shapes define the clickable region of the icon.
  # The type defines an HTML &lt;area&gt; element 'poly' which
  # traces out a polygon as a series of X,Y points. The final
  # coordinate closes the poly by connecting to the first
  # coordinate.
  shape =
      coords: [1, 1, 1, 20, 18, 20, 18 , 1]
      type: 'poly'

  for markerInfo in markersInfo
    myLatLng = new google.maps.LatLng markerInfo[1], markerInfo[2]
    newMarker = new google.maps.Marker
      position: myLatLng
      map: map
      icon: image
      shape: shape
      title: markerInfo[0]
      zIndex: markerInfo[3]