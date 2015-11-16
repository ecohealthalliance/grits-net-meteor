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
    height: 25
    width: 15

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
    if typeof Template.filter.departureSearch != 'undefined'
      tokens =  Template.filter.departureSearch.tokenfield('getTokens')
      match = _.find(tokens, (t) -> t.label == this._id)
      if match
        return false
      else
        tokens.push({label: this._id, value: this.id + " - " + this.metadata.name})
        Template.filter.departureSearch.tokenfield('setTokens', tokens)
        Meteor.gritsUtil.origin = @_id
        $("#departureSearch").val('!' + @_id)
        $("#applyFilter").click()

# GritsNodeLayer
#
# Creates an instance of a node 'svg' layer.
GritsNodeLayer = (options) ->
  @_name = 'Nodes'
  @Nodes = {}

  @maxValue = null

  if typeof options == 'undefined' or options == null
    @options = {}
  else
    @options = options

  @layer = null
  @layerGroup = null
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
  if !(typeof @layerGroup == 'undefined' or @layerGroup == null)
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
  # sort by latitude so markers that are lower appear on top
  nodes = _.sortBy(_.values(@Nodes), (node) ->
    return node.latLng[0] * -1
  )

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
      return x - ((node.marker.width/2) / projection.scale)
    )
    .attr('y', (node) ->
      y = projection.latLngToLayerPoint(node.latLng).y
      return y - ((node.marker.height) / projection.scale)
    )
    .attr('width', (node) ->
      (node.marker.width) / projection.scale
    )
    .attr('height', (node) ->
      (node.marker.height) / projection.scale
    )


  # add new elements workflow (following https://github.com/mbostock/d3/wiki/Selections#enter )
  markers.enter().append('image')
    .attr('xlink:href', (node) ->
      self.getMarkerHref(node)
    )
    .attr('x', (node) ->
      x = projection.latLngToLayerPoint(node.latLng).x
      return x - ((node.marker.width/2) / projection.scale)
    )
    .attr('y', (node) ->
      y = projection.latLngToLayerPoint(node.latLng).y
      return y - ((node.marker.height) / projection.scale)
    )
    .attr('width', (node) ->
      (node.marker.width) / projection.scale
    )
    .attr('height', (node) ->
      (node.marker.height) / projection.scale
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
    href = "/packages/grits_grits-net-meteor/client/images/marker-icon-#{v}.svg"
  else
    href = '/packages/grits_grits-net-meteor/client/images/marker-icon-B8B8B8.svg'
  return href

# draw
#
# Draws the layer on the map
GritsNodeLayer::draw = () ->
  if Object.keys(@Nodes).lenght <= 0
    return
  @layer.draw()
  return

# clear
#
# Clears the Nodes and layers
GritsNodeLayer::clear = () ->
  @Nodes = {}
  @removeLayer()
  @addLayer()

# processFlight
#
#
GritsNodeLayer::convertFlight = (flight) ->
  self = this
  # the departureAirport of the flight
  departure = flight.departureAirport
  if (typeof departure != "undefined" and departure != null and departure.hasOwnProperty('_id'))
    departureNode = self.Nodes[departure._id]
    if (typeof departureNode == "undefined" or departureNode == null)
      try
        departureNode = new GritsNode(departure)
        departureNode.outgoingThroughput = flight.totalSeats
      catch e
        console.error(e.message)
        return
      self.Nodes[departure._id] = departureNode
    else
      departureNode.outgoingThroughput += flight.totalSeats

  # the arrivalAirport of the flight
  arrival = flight.arrivalAirport
  if (typeof arrival != "undefined" and arrival != null and arrival.hasOwnProperty('_id'))
    arrivalNode = self.Nodes[arrival._id]
    if (typeof arrivalNode == "undefined" or arrivalNode == null)
      try
        arrivalNode = new GritsNode(arrival)
        arrivalNode.incomingThroughput = flight.totalSeats
      catch e
        console.error(e.message)
        return
      self.Nodes[arrival._id] = arrivalNode
    else
      arrivalNode.incomingThroughput += flight.totalSeats

  return [departureNode, arrivalNode]
