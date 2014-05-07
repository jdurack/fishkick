# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'page:change', () ->

  updateFishMonthInfoEnabled = (target) ->
    fullTargetName = target.name
    indicatorPrefix = 'siteFishInfo_'
    indicatorSuffix = '['
    targetId = fullTargetName.substring indicatorPrefix.length, fullTargetName.indexOf(indicatorSuffix)
    $('.fishMonthInfo_' + targetId).prop 'disabled', ( if target.checked then false else true )


  $('.hasFishCheckbox').on 'click', (event) ->
    target = event.currentTarget
    updateFishMonthInfoEnabled target
    
  fishCheckboxes = $('.hasFishCheckbox')
  for fishCheckbox in fishCheckboxes
    updateFishMonthInfoEnabled fishCheckbox