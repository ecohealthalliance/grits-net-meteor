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

  longitude = obj.loc.coordinates[0]
  latitude = obj.loc.coordinates[1]

  @_id = obj._id
  @_name = 'Node'

  @marker =
    height: 80
    width: 55

  @latLng = [latitude, longitude]

  @incomingThroughput = 0
  @outgoingThroughput = 0
  @level = 0

  @metadata = {}
  _.extend(@metadata, obj)

  @grayscale =
    9: '282828'
    8: '383838'
    7: '484848'
    6: '585858'
    5: '686868'
    4: '787878'
    3: '888888'
    2: '989898'
    1: 'A8A8A8'
    0: 'B8B8B8'
  return

GritsNode::onClickHandler = (element, selection, projection) ->
  if not Session.get('isUpdating')
    Meteor.gritsUtil.showNodeDetails(this)
    $("#departureSearch").val('!' + @_id)
    $("#applyFilter").click()

# GritsNodeLayer
#
# Creates an instance of a node 'svg' layer.
GritsNodeLayer = (options) ->
  @_name = 'Nodes'
  @Nodes = {}

  #allow the UI to update every 100 iterations
  @UPDATE_COUNT = 100
  @WORKERS = 2

  @minValue = null
  @maxValue = null

  if typeof options == 'undefined' or options == null
    @options = {}
  else
    @options = options

  @layer = null
  @layerGroup = null
  @_bindEvents()
  @addLayer()

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
  @layer = null
  @layerGroup = null
  return
# add
#
# adds the heatmap layerGroup to the map
GritsNodeLayer::addLayer = () ->
  @layer = L.d3SvgOverlay(_.bind(@drawCallback, this), @options)
  @layerGroup = L.layerGroup([@layer])
  Meteor.gritsUtil.addOverlayControl(@_name, @layerGroup)
  Meteor.gritsUtil.map.addLayer(@layerGroup)
  return

# drawCallback
#
# Note: makes used of _.bind within the constructor so 'this' is encapsulated
# properly
GritsNodeLayer::drawCallback = (selection, projection) ->
  self = this
  nodes = _.values(@Nodes)
  nodeCount = nodes.length
  if nodeCount <= 0
    return

  # since the map may be updated asynchronously the sums of the throughput
  # counters must be calcuated on every draw and the self.maxValue set
  sums = _.map(nodes, (node) ->
    node.incomingThroughput + node.outgoingThroughput
  )
  self.maxValue = _.max(sums)

  # select any existing circles and store data onto elements
  markers = selection.selectAll('image').data(nodes, (node) -> node._id)

  #work on existing nodes
  markers
    .attr('xlink:href', (node) ->
      self.getMarkerHref(node)
    )
    .attr('x', (node) ->
      x = projection.latLngToLayerPoint(node.latLng).x
      return x - ((node.marker.width/4) / projection.scale)
    )
    .attr('y', (node) ->
      y = projection.latLngToLayerPoint(node.latLng).y
      return y - ((node.marker.height/3) / projection.scale)
    )
    .attr("width", (node) ->
      (node.marker.width/2) / projection.scale
    )
    .attr("height", (node) ->
      (node.marker.height/2) / projection.scale
    )

  # add new elements workflow (following https://github.com/mbostock/d3/wiki/Selections#enter )
  markers.enter().append('image')
    .attr('xlink:href', (node) ->
      self.getMarkerHref(node)
    )
    .attr('x', (node) ->
      x = projection.latLngToLayerPoint(node.latLng).x
      return x - ((node.marker.width/4) / projection.scale)
    )
    .attr('y', (node) ->
      y = projection.latLngToLayerPoint(node.latLng).y
      return y - ((node.marker.height/3) / projection.scale)
    )
    .attr('width', (node) ->
      (node.marker.width/2) / projection.scale
    )
    .attr('height', (node) ->
      (node.marker.height/2) / projection.scale
    )
    .attr('class', (node) ->
      'marker-icon'
    )
    .on('click', (node) ->
      d3.event.stopPropagation();
      # manual trigger node click handler
      node.onClickHandler(this, selection, projection)
    )
  markers.exit()
  return

GritsNodeLayer::getRelativeThroughput = (node) ->
  maxAllowed = 0.9
  r = 0.0
  if @maxValue > 0
    r = ((node.incomingThroughput + node.outgoingThroughput) / @maxValue)
  if r > maxAllowed
    return maxAllowed
  return +(r).toFixed(1)

GritsNodeLayer::getMarkerHref = (node) ->
  v = node.grayscale[ @getRelativeThroughput(node) * 10]
  if !(typeof v == 'undefined' or v == null)
    href = "/packages/grits_grits-net-meteor/client/images/marker-icon-#{v}.png"
  else
    href = '/packages/grits_grits-net-meteor/client/images/marker-icon-B8B8B8.png'
  return href

# draw
#
# Sets the data for the heatmap plugin and updates the heatmap
GritsNodeLayer::draw = () ->
  @layer.draw()
  return

# clear
#
# Clears the Nodes and layers
GritsNodeLayer::clear = () ->
  @Nodes = {}
  @removeLayer()
  @addLayer()

# convertFlightsToNodes
#
# Helper method that converts the localFlights minimongo cursor into a
# set of nodes
# @param cursor, minimongo cursor of Flights
GritsNodeLayer::convertFlightToNodes = (Flights, done) ->
  self = this
  cursor = Flights.find({}, {fields: {departureAirport: 1, arrivalAirport: 1, totalSeats: 1}})

  count = 0
  nodes = {}

  processQueue = async.queue(((flight, callback) ->
    # the departureAirport of the flight
    departure = flight.departureAirport
    if (typeof departure != "undefined" and departure != null and departure.hasOwnProperty('_id'))
      departureNode = nodes[departure._id]
      if (typeof departureNode == "undefined" or departureNode == null)
        try
          departureNode = new GritsNode(departure)
          departureNode.outgoingThroughput = flight.totalSeats
        catch e
          console.error(e.message)
          return
        nodes[departure._id] = departureNode
      else
        departureNode.outgoingThroughput += flight.totalSeats
    # the arrivalAirport of the flight
    arrival = flight.arrivalAirport
    if (typeof arrival != "undefined" and arrival != null and arrival.hasOwnProperty('_id'))
      arrivalNode = nodes[arrival._id]
      if (typeof arrivalNode == "undefined" or arrivalNode == null)
        try
          arrivalNode = new GritsNode(arrival)
          arrivalNode.incomingThroughput = flight.totalSeats
        catch e
          console.error(e.message)
          return
        nodes[arrival._id] = arrivalNode
      else
        arrivalNode.incomingThroughput += flight.totalSeats

    count++
    async.nextTick ->
      if !(count % self.UPDATE_COUNT)
        # let the UI update every x iterations
        _.extend(self.Nodes, nodes)
        self.draw()
      callback()
  ), self.WORKERS)

  # callback method for when all items within the queue are processed
  processQueue.drain = ->
    _.extend(self.Nodes, nodes)    
    done(null, true)

  processQueue.push(cursor.fetch())
