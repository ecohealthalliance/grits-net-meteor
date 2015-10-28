# GritsNode
#
# Creates an instance of a node that represents a geoJSON point
GritsNode = (obj) ->
  if typeof obj == 'undefined' or obj == null
    throw new Error('A node requires valid input object')
  if obj.hasOwnProperty('loc') == false
    throw new Error('A node requires the "loc" location property')

  @_id = obj._id
  @_name = 'Node'

  # http://geojson.org/geojson-spec.html#point
  @type = 'Point'
  # coordinates are in x,y order (longitude, latitude)
  @coordinates = loc.coordinates

  @metadata = {
    @incomingThroughput: 0
    @outgoingThroughput: 0
    @level: 0
  }

  _.extend(metadata, obj)

  @_bindEvents()
  return
# _bindEvents
#
# Binds to the
GritsNode::_bindEvents = () ->
  self = this

# GritsNodeLayer
#
# Creates an instance of a node 'svg' layer.
GritsNodeLayer = () ->
  @_name = 'Nodes'
  @Nodes = new (Meteor.Collection)(null)
  @layer = L.svg()
  @layerGroup = L.layerGroup([@layer])
  Meteor.gritsUtil.addOverlayControl(@_name, @layerGroup)
  @_bindEvents()
  return
# _bindEvents
#
# Binds to the global map.on 'overlyadd' and 'overlayremove' methods
GritsNodeLayer::_bindEvents = () ->
  self = this
  Meteor.gritsUtil.map.on(
    overlayadd: (e) ->
      if e.name == self._name
        if Meteor.gritsUtil.debug
          console.log self._name + ' added'
    overlayremove: (e) ->
      if e.name == self._name
        if Meteor.gritsUtil.debug
          console.log self._name + ' removed'
  )
# remove
#
# removes the heatmap layerGroup from the map
GritsNodeLayer::removeLayer = () ->
  Meteor.gritsUtil.map.removeLayer(@layerGroup)
# add
#
# adds the heatmap layerGroup to the map
GritsNodeLayer::addLayer = () ->
  Meteor.gritsUtil.addOverlayControl(@_name, @layerGroup)
# draw
#
# Sets the data for the heatmap plugin and updates the heatmap
GritsNodeLayer::draw = () ->
  if @Nodes.find().count() == 0
    throw new Error 'The layer does not contain any nodes'
    return

  nodes = @Nodes.find({}).fetch();
  pointData = _.pluck(points, '')
  console.log 'draw::layer.setLatLngs'
  @layer.setLatLngs(pointData)
# clear
#
# Clears the Nodes from collection
GritsNodeLayer::clear = () ->
  @Nodes.remove({});
GritsNodeLayer::addNode = (node) ->
  @Nodes.upsert(node._id, node)
GritsNodeLayer::removeNode = (node) ->
  @Nodes.remove(node._id)
# convertFlightsToNodes
#
# Helper method that onverts the localFlights minimongo cursor into a
# set of nodes
# @param cursor, minimongo cursor of Flights
GritsNodeLayer::convertFlightToNodes = (cursor) ->
  self = this
  cursor.forEach (flight) ->
    departure = flight.departureAirport
    departureNode = null
    if typeof departure != "undefined" and departure != null
      try
        departureNode = new GritsNode(departure)
      catch e
        console.error(e.message)
      self.addNode(departureNode)

    arrival = flight.arrivalAirport
    arrivalNode = null
    if typeof arrival != "undefined" and arrival != null
      try
        arrivalNode = new GritsNode(arrival)
      catch e
        console.error(e.message)
      self.addNode(arrivalNode)
