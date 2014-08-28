
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

window.FK.initializeTopScoreController = () ->

  angular.module('fishKickApp', ['google-maps'.ns()]).controller 'TopScoreCtrl', ["$scope", ($scope) ->

    $scope.googleMapOptions =
      mapTypeId: google.maps.MapTypeId.TERRAIN
      streetViewControl: false

    $scope.googleMap = {}
    $scope.map =
      center:
        latitude: 40.8688
        longitude: -123.2295
      zoom: 8
    $scope.maxZoom = 12
    $scope.minZoom = 9

    if window.FK.topScores
      $scope.topScores = window.FK.topScores
    else
      $scope.topScores = []
    
    $scope.$watch 'fishSelect', () ->
      window.FK.zoomToFit $scope

    $scope.$watch 'topScores', () ->
      window.FK.zoomToFit $scope
  ]
      

window.FK.getTopScoresAngularScope = () ->
  scope = angular.element(document.getElementById("topScores")).scope()
  scope


window.FK.zoomToFit = ( scope ) ->

  unless scope
    scope = window.FK.getTopScoresAngularScope()
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
