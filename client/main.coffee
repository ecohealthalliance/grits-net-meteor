Meteor.startup ->
  window.LUtil.initLeaflet()
  $('.map').click()
Template.body.helpers template_name: ->
  Session.get 'module'
currentPaths = []
Template.body.events
  'click .a': ->
    Session.set 'module', 'a'    
    srcNode = new L.MapNode(new L.LatLng(15.721201, -115.428235), window.LUtil.map)
    srcNode.setPopup("src")
    destNode = new L.MapNode(new L.LatLng(70.022733, -115.428235), window.LUtil.map)
    destNode.setPopup("dest")
    mapPath = new L.mapPath(srcNode, destNode)
    mapPath.drawPath('red', 5, window.LUtil.map)   
  'click .b': ->
    Session.set 'module', 'b'
    #pointList.push new L.LatLng(window.LUtil.getRandomLatLng()[0],window.LUtil.getRandomLatLng()[1]) for num in [1..2]
    srcNode = new L.MapNode(new L.LatLng(35.721201, -85.428235), window.LUtil.map)
    srcNode.setPopup("src")
    destNode = new L.MapNode(new L.LatLng(20.022733, -25.428235), window.LUtil.map)
    destNode.setPopup("dest")
    mapPath = new L.mapPath(srcNode, destNode)
    mapPath.drawPath('green', 10, window.LUtil.map)    
  'click .c': ->
    Session.set 'module', 'c'
    #pointList.push new L.LatLng(window.LUtil.getRandomLatLng()[0],window.LUtil.getRandomLatLng()[1]) for num in [1..2]
    srcNode = new L.MapNode(new L.LatLng(20.022733, -85.428235), window.LUtil.map)
    srcNode.setPopup("src")
    destNode = new L.MapNode(new L.LatLng(35.721201, -25.428235), window.LUtil.map)
    destNode.setPopup("dest")
    mapPath = new L.mapPath(srcNode, destNode)
    mapPath.drawPath('blue', 15, window.LUtil.map)    
  'click .d': ->
    Session.set 'module', 'd'
    srcNode = new L.MapNode(new L.LatLng(15.721201, -110.428235), window.LUtil.map)
    srcNode.setPopup("src")
    destNode = new L.MapNode(new L.LatLng(15.022733, -115.428235), window.LUtil.map)
    destNode.setPopup("dest")    
    mapPath = new L.mapPath(srcNode, destNode)
    mapPath.drawPath('orange', 20, window.LUtil.map)    
  'click .e': ->
    Session.set 'module', 'e'
    srcNode = new L.MapNode(new L.LatLng(17.022733, -115.428235), window.LUtil.map)
    srcNode.setPopup("src")
    destNode = new L.MapNode(new L.LatLng(57.749264, 129.576109), window.LUtil.map)    
    destNode.setPopup("dest")    
    mapPath = new L.mapPath(srcNode, destNode)
    mapPath.drawPath('white', 3, window.LUtil.map)    