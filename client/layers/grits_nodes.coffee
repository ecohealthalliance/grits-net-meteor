_eventHandlers = {
  #mouseover: (element, selection, projection) ->
  #  if not Session.get('grits-net-meteor:isUpdating')
  #    Template.gritsMap.showNodeDetails(this)
  click: (element, selection, projection) ->
    self = this
    if not Session.get('grits-net-meteor:isUpdating')
      departureSearch = Template.gritsFilter.getDepartureSearch()
      if typeof departureSearch != 'undefined'
        rawTokens =  departureSearch.tokenfield('getTokens')
        tokens = _.pluck(rawTokens, 'label')
        match = _.find(tokens, (t) -> t == self._id)
        if match
          # this token was already used in the query
          Template.gritsMap.showNodeDetails(this)
          return
        else
          # erase any previous departures
          GritsFilterCriteria.setDeparture(null)
          # set the clicked element as the new origin
          departureSearchMain = Template.gritsFilter.getDepartureSearchMain()
          departureSearchMain.tokenfield('setTokens', [self._id])
          # apply the filter
          GritsFilterCriteria.scanAll()
          GritsFilterCriteria.applyWithCallback((err, res) ->
            if res
              map = Template.gritsMap.getInstance()              
              if map.getZoom() > 2
                # panto the map if we're at zoom level 3 or greater
                map.panTo(self.latLng)
              else
                # set the view to the latLng and zoom level to 2
                map.setView(self.latLng, 2)
              Template.gritsMap.showNodeDetails(self)
          )
    return
}
# custom color scale for each marker
_colorScale =
  9: 'F9A839'
  8: 'F9AF40'
  7: 'F9B747'
  6: 'F9BE4E'
  5: 'F9C656'
  4: 'F9CE5D'
  3: 'F9D564'
  2: 'F9DD6B'
  1: 'F9E573'


# Creates an instance of a GritsNodeLayer, extends  GritsLayer
#
# @param [Object] map, an instance of GritsMap
class GritsNodeLayer extends GritsLayer
  constructor: (map) ->
    GritsLayer.call(this) # invoke super constructor
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
  
  # The D3 callback that renders the svg elements on the map
  #
  # @see https://github.com/mbostock/d3/wiki/API-Reference
  # @see https://github.com/mbostock/d3/wiki/Selections
  # @param [Object] selection, teh array of elements pulled from the current
  #   document, also includes helper methods for filtering similar to jQuery  
  # @param [Object] projection, the current scale
  _drawCallback: (selection, projection) ->
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
    markers = selection.selectAll('circle').data(nodes, (node) -> node._id)
  
    #work on existing nodes
    markers
      .attr('cx', (node) ->
        x = projection.latLngToLayerPoint(node.latLng).x
        return x - ((node.marker.width/2) / projection.scale)
      )
      .attr('cy', (node) ->
        y = projection.latLngToLayerPoint(node.latLng).y
        return y - ((node.marker.height/2) / projection.scale)
      )
      .attr('r', (node) ->
        (node.marker.width) / projection.scale
      )
      .attr('fill', (node) ->
        '#'+self._getMarkerColor(node)
      )
      .attr('fill-opacity', .8)
  
  
    # add new elements workflow (following https://github.com/mbostock/d3/wiki/Selections#enter )
    markers.enter().append('circle')
      .attr('cx', (node) ->
        x = projection.latLngToLayerPoint(node.latLng).x
        return x - ((node.marker.width/2) / projection.scale)
      )
      .attr('cy', (node) ->
        y = projection.latLngToLayerPoint(node.latLng).y
        return y - ((node.marker.height/2) / projection.scale)
      )
      .attr('r', (node) ->
        (node.marker.width) / projection.scale
      )
      .attr('fill', (node) ->
        '#'+self._getMarkerColor(node)
      )
      .attr('fill-opacity', .8)
      .attr('class', (node) ->
        'marker-icon'
      )
      .on('click', (node) ->
        d3.event.stopPropagation();
        # manual trigger node click handler
        if node.hasOwnProperty('eventHandlers')
          if node.eventHandlers.hasOwnProperty('click')
            node.eventHandlers.click(this, selection, projection)
      )
      .on('mouseover', (node) ->
        d3.event.stopPropagation();
        # manual trigger node mouseover handler
        if node.hasOwnProperty('eventHandlers')
          if node.eventHandlers.hasOwnProperty('mouseover')
            node.eventHandlers.mouseover(this, selection, projection)
      )
    markers.exit()
    return
  
  # converts domain specific flight data into generic GritsNode nodes
  # 
  # @param [Object] flight, an Astronomy class 'Flight' represending a single
  #   record from a MongoDB collection
  convertFlight: (flight) ->
    self = this
    # the departureAirport of the flight
    departure = flight.departureAirport
    if (typeof departure != "undefined" and departure != null and departure.hasOwnProperty('_id'))
      departureNode = self._data[departure._id]
      if (typeof departureNode == "undefined" or departureNode == null)
        try
          marker = new GritsMarker(7, 7, _colorScale)
          departureNode = new GritsNode(departure, marker)
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
          marker = new GritsMarker(7, 7, _colorScale)
          arrivalNode = new GritsNode(arrival, marker)
          arrivalNode.setEventHandlers(_eventHandlers)
          arrivalNode.incomingThroughput = flight.totalSeats
        catch e
          console.error(e.message)
          return
        self._data[arrival._id] = arrivalNode
      else
        arrivalNode.incomingThroughput += flight.totalSeats
  
    return [departureNode, arrivalNode]
  
  # returns the normalized throughput for a node
  #
  # @return [Number] normalizedThroughput, 0 >= n <= .9 
  _getNormalizedThroughput: (node) ->
    maxAllowed = 0.9
    r = 0.0
    if @_normalizedCI > 0
      r = ((node.incomingThroughput + node.outgoingThroughput) / @_normalizedCI)
    if r > maxAllowed
      return maxAllowed
    return +(r).toFixed(1)
  
  # returns the href to use as the marker image
  #
  # @return [String] href, the marker image src
  _getMarkerHref: (node) ->
    v = node.marker.colorScale[@_getNormalizedThroughput(node) * 10]
    if !(typeof v == 'undefined' or v == null)
      href = '/packages/grits_grits-net-mapper/images/marker-icon-#{v}.svg'
    else
      href = '/packages/grits_grits-net-mapper/images/marker-icon-B8B8B8.svg'
    return href

  # returns the color to use as the marker fill
  #
  # @return [String] color, the marker image color
  _getMarkerColor: (node) ->
    v = node.marker.colorScale[@_getNormalizedThroughput(node) * 10]
    if !(typeof v == 'undefined' or v == null)
      color = v
    else
      color = 'DB943E'
    return color 
  
  # binds to the Tracker.gritsMap.getInstance() map event listener .on
  # 'overlyadd' and 'overlayremove' methods
  _bindMapEvents: () ->
    self = this
    if typeof self._map == 'undefined'
      return  
    self._map.on(
      overlayadd: (e) ->
        if e.name == self._name
          if Meteor.gritsUtil.debug
            console.log self._name + ' added'
      overlayremove: (e) ->
        if e.name == self._name
          if Meteor.gritsUtil.debug
            console.log self._name + ' removed'
    )