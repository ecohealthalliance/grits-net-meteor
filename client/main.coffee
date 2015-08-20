Meteor.startup ->
  Meteor.grits_net_mapper.initLeaflet()
  $('.map').click()
Template.body.helpers template_name: ->
  Session.get 'module'
Template.body.events
  'click .a': ->
    Session.set 'module', 'a'
    pointA = new L.LatLng(40.206546, -79.114908)
    pointB = new (L.LatLng)(38.924456, -114.809684)
    pointList = [pointA, pointB];
    Meteor.grits_net_mapper.drawPath pointList
  'click .b': ->
    Session.set 'module', 'b'
  'click .c': ->
    Session.set 'module', 'c'
  'click .d': ->
    Session.set 'module', 'd'
  'click .e': ->
    Session.set 'module', 'e'