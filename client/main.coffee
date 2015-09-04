Meteor.startup ->
  window.LUtil.initLeaflet()
  $('.map').click()
Template.body.helpers template_name: ->
  Session.get 'module'


Meteor.dummyFlight1 = [{ "_id" : { "$oid" : "55e0a2c72070b47daed4347b"} , "Alliance" : "None" , "Arr Flag" : true , "Arr Term" : "E " , "Arr Time" : 1700.0 , "Block Mins" : 480.0 , "Date" : { "$date" : 1391212800000} , "Dep Term" :  null  , "Dep Time" : 1300.0 , "Dest" : { "City" : "Boston" , "Global Region" : "North America" , "Code" : "BOS" , "Name" : "Logan International" , "loc" : { "type" : "Point" , "coordinates" : [ -115.428235, 70.022733 ]} , "Country" :  null  , "Notes" :  null  , "WAC" : 13 , "State Name" : "Massachusetts" , "State" : "MA" , "Country Name" : "United States" , "key" : "BOS" , "_id" : { "$oid" : "55e0a2862070b47daed4104f"}} , "Dest WAC" : 13 , "Equip" : "752" , "Flight" : 690 , "Miles" :  null  , "Mktg Al" : "VR" , "Op Al" : "VR" , "Op Days" : "...4..." , "Ops/Week" : 1 , "Orig" : { "City" : "Praia" , "Global Region" : "Africa" , "Code" : "RAI" , "Name" : "Praia International" , "loc" : { "type" : "Point" , "coordinates" : [ -115.428235, 15.721201]} , "Country" :  null  , "Notes" :  null  , "WAC" : 507 , "State Name" :  null  , "State" :  null  , "Country Name" : "Cape Verde" , "key" : "RAI" , "_id" : { "$oid" : "55e0a2a62070b47daed42c34"}} , "Orig WAC" : 507 , "Seats" : 210 , "Seats/Week" : 210 , "Stops" : 0 , "key" : "04108e946db07b47ad21875e61c43b8e702b877688962343b8610b65d62555a7"}]
Meteor.dummyFlight2 = [{ "_id" : { "$oid" : "55e0a2c72070b47daed4347b"} , "Alliance" : "None" , "Arr Flag" : true , "Arr Term" : "E " , "Arr Time" : 1700.0 , "Block Mins" : 480.0 , "Date" : { "$date" : 1391212800000} , "Dep Term" :  null  , "Dep Time" : 1300.0 , "Dest" : { "City" : "Boston" , "Global Region" : "North America" , "Code" : "BOS" , "Name" : "Logan International" , "loc" : { "type" : "Point" , "coordinates" : [ 129.576109, 57.749264]} , "Country" :  null  , "Notes" :  null  , "WAC" : 13 , "State Name" : "Massachusetts" , "State" : "MA" , "Country Name" : "United States" , "key" : "BOS" , "_id" : { "$oid" : "55e0a2862070b47daed4104f"}} , "Dest WAC" : 13 , "Equip" : "752" , "Flight" : 690 , "Miles" :  null  , "Mktg Al" : "VR" , "Op Al" : "VR" , "Op Days" : "...4..." , "Ops/Week" : 1 , "Orig" : { "City" : "Praia" , "Global Region" : "Africa" , "Code" : "RAI" , "Name" : "Praia International" , "loc" : { "type" : "Point" , "coordinates" : [ -115.428235, 17.022733]} , "Country" :  null  , "Notes" :  null  , "WAC" : 507 , "State Name" :  null  , "State" :  null  , "Country Name" : "Cape Verde" , "key" : "RAI" , "_id" : { "$oid" : "55e0a2a62070b47daed42c34"}} , "Orig WAC" : 507 , "Seats" : 210 , "Seats/Week" : 210 , "Stops" : 0 , "key" : "04108e946db07b47ad21875e61c43b8e702b877688962343b8610b65d62555a7"}]



Meteor.buildFlight =
  build:(flight) ->
    mapPath = new L.mapPath(flight, window.LUtil.map)


Template.body.events
  'click .a': ->
    Meteor.buildFlight.build(Meteor.dummyFlight1[0])
  'click .b': ->
     Meteor.buildFlight.build(Meteor.dummyFlight2[0])
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
