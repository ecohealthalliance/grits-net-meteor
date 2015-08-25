Meteor.startup ->
  window.LUtil.initLeaflet()
  $('.map').click()
Template.body.helpers template_name: ->
  Session.get 'module'
currentPaths = []
Template.body.events
  'click .a': ->
    Session.set 'module', 'a'
    pointList = []
    #pointList.push new L.LatLng(window.LUtil.getRandomLatLng()[0],window.LUtil.getRandomLatLng()[1]) for num in [1..2]  
    pointList.push new L.LatLng(37.721201, -115.428235)
    pointList.push new L.LatLng(37.022733, -80.140149)
    mapPath = new L.mapPath pointList
    mapPath.drawPath('red', 5, window.LUtil.map)    
  'click .b': ->
    Session.set 'module', 'b'
    pointList = []
    mapPath = new L.mapPath pointList
    mapPath.drawPath('red', 5, window.LUtil.map) 
  'click .c': ->
    Session.set 'module', 'c'
    pointList = []
    pointList.push new L.LatLng(window.LUtil.getRandomLatLng()[0],window.LUtil.getRandomLatLng()[1]) for num in [1..10]
    mapPath = new L.mapPath pointList
    mapPath.drawPath('red', 5, window.LUtil.map) 
  'click .d': ->
    Session.set 'module', 'd'
    pointList = []
    pointList.push new L.LatLng(window.LUtil.getRandomLatLng()[0],window.LUtil.getRandomLatLng()[1]) for num in [1..10]
    mapPath = new L.mapPath pointList
    mapPath.drawPath('red', 5, window.LUtil.map) 
  'click .e': ->
    Session.set 'module', 'e'
    pointList = []
    pointList.push new L.LatLng(window.LUtil.getRandomLatLng()[0],window.LUtil.getRandomLatLng()[1]) for num in [1..10]
    mapPath = new L.mapPath pointList
    mapPath.drawPath('red', 5, window.LUtil.map) 