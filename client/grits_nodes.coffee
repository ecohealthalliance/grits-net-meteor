# GritsNode
#
# Creates an instance of a node that represents a geoJSON point
GritsNode = (obj) ->
  if typeof obj == 'undefined' or obj == null
    throw new Error('A node requires valid input object')
    return

  if obj.hasOwnProperty('_id') == false
    throw new Error('A node requires the "_id" location property')
    return

  if obj.hasOwnProperty('loc') == false
    throw new Error('A node requires the "loc" location property')
    return

  @_id = obj._id
  @_name = 'Node'

  @radius = 5
  @marker =
    height: 80
    width: 55
    href: '/packages/grits_grits-net-meteor/client/images/marker-icon-B8B8B8.png'

  @latLng = [obj.loc.coordinates[1], obj.loc.coordinates[0]]

  @metadata =
    incomingThroughput: 0
    outgoingThroughput: 0
    level: 0

  _.extend(@metadata, obj)
  return


# GritsNodeLayer
#
# Creates an instance of a node 'svg' layer.
GritsNodeLayer = (options) ->
  @_name = 'Nodes'
  @Nodes = new (Meteor.Collection)(null)

  if typeof options == 'undefined' or options == null
    @options = {}
  else
    @options = options

  @layer = L.d3SvgOverlay(_.bind(@drawCallback, this), options)
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
  return
# add
#
# adds the heatmap layerGroup to the map
GritsNodeLayer::addLayer = () ->
  Meteor.gritsUtil.map.addLayer(@layerGroup)
  return
# drawCallback
#
# Note: makes used of _.bind within the constructor so 'this' is encapsulated
# properly
GritsNodeLayer::drawCallback = (selection, projection) ->
  nodeCount = @Nodes.find().count()
  if nodeCount <= 0
    return
  nodes = @Nodes.find({}).fetch()

  # select any existing circles and store data onto elements
  markers = selection.selectAll('image').data(nodes, (node) -> node._id)
  #labels = selection.selectAll('text').data(nodes, (node) -> node._id)

  #work on existing nodes
  markers
    .attr('x', (node) ->
      x = projection.latLngToLayerPoint(node.latLng).x
      return x - ((node.marker.width/4) / projection.scale)
    )
    .attr('y', (node) ->
      y = projection.latLngToLayerPoint(node.latLng).y
      return y - ((node.marker.height/4) / projection.scale)
    )
    .attr("width", (node) ->
      (node.marker.width/2) / projection.scale
    )
    .attr("height", (node) ->
      (node.marker.height/2) / projection.scale
    )
  ###
  labels
    .attr('font-size', 14 / projection.scale)
    .attr('dx', (node) ->
      projection.latLngToLayerPoint(node.latLng).x
    )
    .attr('dy', (node) ->
      projection.latLngToLayerPoint(node.latLng).y
    )
    .text((node) ->
       return node.metadata.name
    )
  ###


  # add new elements workflow (following https://github.com/mbostock/d3/wiki/Selections#enter )
  markers.enter().append('image')
    .attr('xlink:href', (node) ->
      node.marker.href
    )
    .attr('x', (node) ->
      x = projection.latLngToLayerPoint(node.latLng).x
      return x - ((node.marker.width/4) / projection.scale)
    )
    .attr('y', (node) ->
      y = projection.latLngToLayerPoint(node.latLng).y
      return y - ((node.marker.height/4) / projection.scale)
    )
    .attr("width", (node) ->
      (node.marker.width/2) / projection.scale
    )
    .attr("height", (node) ->
      (node.marker.height/2) / projection.scale
    )
  markers.exit()
  ###
  labels.enter().append('text')
    .attr('font-size', 12 / projection.scale)
    .attr('dx', (node) ->
      projection.latLngToLayerPoint(node.latLng).x
    )
    .attr('dy', (node) ->
      projection.latLngToLayerPoint(node.latLng).y
    )
    .text((node) ->
       return node.metadata.name
    )
  labels.exit()
  ###
  return

# draw
#
# Sets the data for the heatmap plugin and updates the heatmap
GritsNodeLayer::draw = () ->
  if @Nodes.find().count() == 0
    throw new Error 'The layer does not contain any nodes'
    return
  @removeLayer()
  @addLayer()
  return

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
# Helper method that converts the localFlights minimongo cursor into a
# set of nodes
# @param cursor, minimongo cursor of Flights
GritsNodeLayer::convertFlightToNodes = (cursor, cb) ->
  self = this
  count = 0
  cursorCount = cursor.count()
  cursor.forEach((flight) ->
    setTimeout(() ->
      departure = flight.departureAirport
      departureNode = null
      if typeof departure != "undefined" and departure != null
        try
          departureNode = new GritsNode(departure)
        catch e
          console.error(e.message)
          return
        self.addNode(departureNode)

      arrival = flight.arrivalAirport
      arrivalNode = null
      if typeof arrival != "undefined" and arrival != null
        try
          arrivalNode = new GritsNode(arrival)
        catch e
          console.error(e.message)
          return
        self.addNode(arrivalNode)
      if cursorCount == ++count
        cb(null, true)
    , 0)
  )
