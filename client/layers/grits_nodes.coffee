_eventHandlers = {
  mouseover: (element, selection, projection) ->
    if not Session.get('grits-net-meteor:isUpdating')
      Template.gritsMap.showNodeDetails(this)
  click: (element, selection, projection) ->
    if not Session.get('grits-net-meteor:isUpdating')
      Template.gritsMap.showNodeDetails(this)
      if typeof Template.gritsFilter.departureSearch != 'undefined'
        tokens =  Template.gritsFilter.departureSearch.tokenfield('getTokens')
        match = _.find(tokens, (t) -> t.label == this._id)
        if match
          return false
        else
          tokens.push({label: this._id, value: this._id + " - " + this.metadata.name})
          Template.gritsFilter.departureSearch.tokenfield('setTokens', tokens)
      GritsFilterCriteria.scan.departure()
      GritsFilterCriteria.apply()
}

GritsNodeLayer = (map) ->
  GritsLayer.call(this)
  
  if typeof map == 'undefined'
    throw new Error('A layer requires a map to be defined')
    return
  if !map instanceof GritsMap
    throw new Error('A layer requires a valid map instance')
    return
  
  @_name = 'Nodes'
  @_map = map
  
  @_layer = L.d3SvgOverlay(_.bind(@_drawCallback, this), {})
  
  @_bindMapEvents()
  return

GritsNodeLayer.prototype = Object.create(GritsLayer.prototype)
GritsNodeLayer.prototype.constructor = GritsNodeLayer

GritsNodeLayer::_drawCallback = (selection, projection) ->
  self = this
  # sort by latitude so markers that are lower appear on top
  nodes = _.sortBy(_.values(self._data), (node) ->
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
  self._normalizedCI = _.max(sums)

  # select any existing circles and store data onto elements
  markers = selection.selectAll('image').data(nodes, (node) -> node._id)

  #work on existing nodes
  markers
    .attr('xlink:href', (node) ->
      self._getMarkerHref(node)
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
      self._getMarkerHref(node)
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
      node.eventHandlers.click(this, selection, projection)
    )
    .on('mouseover', (node) ->
      d3.event.stopPropagation();
      # manual trigger node mouseover handler
      node.eventHandlers.mouseover(this, selection, projection)
    )
  markers.exit()
  return

GritsNodeLayer::convertFlight = (flight) ->
  self = this
  # the departureAirport of the flight
  departure = flight.departureAirport
  if (typeof departure != "undefined" and departure != null and departure.hasOwnProperty('_id'))
    departureNode = self._data[departure._id]
    if (typeof departureNode == "undefined" or departureNode == null)
      try
        departureNode = new GritsNode(departure)
        departureNode.setEventHandlers(_eventHandlers)
        departureNode.outgoingThroughput = flight.totalSeats
      catch e
        console.error(e.message)
        return
      self._data[departure._id] = departureNode
    else
      departureNode.outgoingThroughput += flight.totalSeats

  # the arrivalAirport of the flight
  arrival = flight.arrivalAirport
  if (typeof arrival != "undefined" and arrival != null and arrival.hasOwnProperty('_id'))
    arrivalNode = self._data[arrival._id]
    if (typeof arrivalNode == "undefined" or arrivalNode == null)
      try
        arrivalNode = new GritsNode(arrival)
        arrivalNode.setEventHandlers(_eventHandlers)
        arrivalNode.incomingThroughput = flight.totalSeats
      catch e
        console.error(e.message)
        return
      self._data[arrival._id] = arrivalNode
    else
      arrivalNode.incomingThroughput += flight.totalSeats

  return [departureNode, arrivalNode]
  
GritsNodeLayer::_getNormalizedThroughput = (node) ->
  maxAllowed = 0.9
  r = 0.0
  if @_normalizedCI > 0
    r = ((node.incomingThroughput + node.outgoingThroughput) / @_normalizedCI)
  if r > maxAllowed
    return maxAllowed
  return +(r).toFixed(1)

GritsNodeLayer::_getMarkerHref = (node) ->
  v = node.marker.colorScale[@_getNormalizedThroughput(node) * 10]
  if !(typeof v == 'undefined' or v == null)
    href = "/packages/grits_grits-net-mapper/images/marker-icon-#{v}.svg"
  else
    href = '/packages/grits_grits-net-mapper/images/marker-icon-B8B8B8.svg'
  return href

# _bindMapEvents
#
# Binds to the global map.on 'overlyadd' and 'overlayremove' methods
GritsNodeLayer::_bindMapEvents = () ->
  self = this
  @_map.map.on(
    overlayadd: (e) ->
      if e.name == self._name
        if Meteor.gritsUtil.debug
          console.log self._name + ' added'
    overlayremove: (e) ->
      if e.name == self._name
        if Meteor.gritsUtil.debug
          console.log self._name + ' removed'
  )