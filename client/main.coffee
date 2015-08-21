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
    pointList.push new L.LatLng(window.LUtil.getRandomLatLng()[0],window.LUtil.getRandomLatLng()[1]) for num in [1..10]    
    L.Mapper.drawPath(pointList, 'red', 5, window.LUtil.map)    
  'click .b': ->
    Session.set 'module', 'b'
    pointList = []
    pointList.push new L.LatLng(window.LUtil.getRandomLatLng()[0],window.LUtil.getRandomLatLng()[1]) for num in [1..10]
    path = new L.Mapper.drawPath(pointList, 'blue', 10, window.LUtil.map)
    popup = L.popup().setLatLng(pointA).setContent('<p>Path Details:<br />Origin:<br />Destination:</p>').openOn(window.LUtil.map)    
    path.bindPopup(popup).openPopup()
  'click .c': ->
    Session.set 'module', 'c'
    pointList = []
    pointList.push new L.LatLng(window.LUtil.getRandomLatLng()[0],window.LUtil.getRandomLatLng()[1]) for num in [1..10]
    L.Mapper.drawPath(pointList, 'green', 15, window.LUtil.map)
  'click .d': ->
    Session.set 'module', 'd'
    pointList = []
    pointList.push new L.LatLng(window.LUtil.getRandomLatLng()[0],window.LUtil.getRandomLatLng()[1]) for num in [1..10]
    L.Mapper.drawPath(pointList, 'black', 20, window.LUtil.map)
  'click .e': ->
    Session.set 'module', 'e'
    pointList = []
    pointList.push new L.LatLng(window.LUtil.getRandomLatLng()[0],window.LUtil.getRandomLatLng()[1]) for num in [1..10]
    L.Mapper.drawPath(pointList, 'orange', 25, window.LUtil.map)