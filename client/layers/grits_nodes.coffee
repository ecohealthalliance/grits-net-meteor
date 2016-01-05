_previousNode = new ReactiveVar(null) # placeholder for a previously selected node
_eventHandlers = {
  #mouseover: (element, selection, projection) ->
  #  if not Session.get('grits-net-meteor:isUpdating')
  #    _previousNode.set(this)
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
          _previousNode.set(this)
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
              pathLayer = map.getGritsLayer('Paths')
              if map.getZoom() > 2
                # panto the map if we're at zoom level 3 or greater
                map.panTo(self.latLng)
              else
                # set the view to the latLng and zoom level to 2
                map.setView(self.latLng, 2)
              # reset the current path
              pathLayer.currentPath.set(null)
              # set previous/current node to self
              _previousNode.set(self)
          )
    return
}
# custom color scale for each marker
_colorScale =
  10: '#D95F0E'
  20: '#DD6F21'
  30: '#E18034'
  40: '#E9A25B'
  50: '#E89B53'
  60: '#EEB36E'
  70: '#F2C482'
  80: '#F6D595'
  90: '#FAE6A8'
  100: '#FFF7BC'
# custom [width, height] size for each marker
_size = [7, 7]


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

    @_prefixDOMID = 'node-'

    @hasLoaded = new ReactiveVar(false)
    @currentNode = _previousNode

    @_bindMapEvents()
    return

  # clears the layer
  #
  # @override
  clear: () ->
    @_data = {}
    @_normalizedCI = 1
    @_removeLayerGroup()
    @_addLayerGroup()
    @hasLoaded.set(false)

  # draws the layer
  #
  # @override
  draw: () ->
    self = this
    self._layer.draw()
    self._moveOriginsToTop()
    return
  
  # moves the origins to the top of the node layer
  _moveOriginsToTop: () ->
    self = this
    origins = self.getOrigins()
    _.each(origins, (node) ->
      $n = $('#'+self.getElementID(node))
      $g = $n.closest('g')
      $n.detach().appendTo($g)
    )
    return
  
  # gets the nodes from the layer
  #
  # @return [Array] array of nodes
  getNodes: () ->
    return _.values(@_data)

  # gets the origins from the layer
  #
  # @return [Array] array of nodes
  getOrigins: () ->
    self = this
    nodes = self.getNodes()
    origins = _.filter(nodes, (node) ->
      if node.hasOwnProperty('isOrigin')
        if node.isOrigin
          return node
    )
    return origins

  # gets the destinations from the layer
  #
  # @return [Array] array of nodes
  getDestinations: () ->
    self = this
    nodes = self.getNodes()
    destinations = _.filter(nodes, (node) ->
      if !node.hasOwnProperty('isOrigin')
        return node
      else
        if !node.isOrigin
          return node
    )
    return destinations

  # gets the element ID within the DOM of a path
  #
  # @param [Object] obj, a gritsNode object
  # @return [String] elementID
  getElementID: (obj) ->
    return @_prefixDOMID + obj._id

  # find a node by the latLng pair
  #
  # @param [Array] an array [lat,lng]
  # @return [Object] a GritsNode object
  findByLatLng: (latLng) ->
    nodes = @getNodes()
    node = _.find(nodes, (node) ->
      return _.isEqual(node.latLng, latLng)
    )
    if _.isUndefined(node)
      return null
    return node

  # The D3 callback that renders the svg elements on the map
  #
  # @see https://github.com/mbostock/d3/wiki/API-Reference
  # @see https://github.com/mbostock/d3/wiki/Selections
  # @param [Object] selection, the array of elements pulled from the current document, also includes helper methods for filtering similar to jQuery
  # @param [Object] projection, the current scale
  _drawCallback: (selection, projection) ->
    self = this
    self._destinationDrawCallback(selection, projection)
    self._originDrawCallback(selection, projection)
    return
  
  _destinationDrawCallback: (selection, projection) ->
    self = this
    
    destinations = self.getDestinations()
    destinationCount = destinations.length
    if destinationCount <= 0
      return

    # since the map may be updated asynchronously the sums of the throughput
    # counters must be calcuated on every draw and the self._normalizedCI set
    # @note we only normalize the destinations.
    sums = _.map(destinations, (destination) ->
      destination.incomingThroughput + destination.outgoingThroughput
    )
    # store the max value to the layer
    self._normalizedCI = _.max(sums)

    # select any existing circles and store data onto elements
    destinationMarkers = selection.selectAll('.destination.marker-icon').data(destinations, (destination) ->
      destination._id
    )
    
    #work on existing nodes
    destinationMarkers
      .attr('cx', (node) ->
        return self._projectCX(projection, node)
      )
      .attr('cy', (node) ->
        return self._projectCY(projection, node)
      )
      .attr('r', (node) ->
        return (node.marker.width) / projection.scale
      )
      .attr('fill', (node) ->
        return self._getNormalizedColor(node)
      )
      .attr('fill-opacity', .8)
      .sort((a,b) ->
        return d3.descending(a.latLng[0], b.latLng[0])
      )

    # add new elements workflow (following https://github.com/mbostock/d3/wiki/Selections#enter )
    destinationMarkers.enter().append('circle')
      .attr('cx', (node) ->
        return self._projectCX(projection, node)
      )
      .attr('cy', (node) ->
        return self._projectCY(projection, node)
      )
      .attr('r', (node) ->
        return (node.marker.width) / projection.scale
      )
      .attr('fill', (node) ->
        return self._getNormalizedColor(node)
      )
      .attr('fill-opacity', .8)
      .attr('class', (node) ->
        return 'destination marker-icon'
      )
      .attr('id', (node) ->
        node.elementID = self.getElementID(node)
        return node.elementID
      )
      .sort((a,b) ->
        return d3.descending(a.latLng[0], b.latLng[0])
      )
      .on('click', (node) ->
        d3.event.stopPropagation();
        # manual trigger node click handler
        if node.hasOwnProperty('eventHandlers')
          if node.eventHandlers.hasOwnProperty('click')
            node.eventHandlers.click(this, selection, projection)
        return
      )
      .on('mouseover', (node) ->
        d3.event.stopPropagation();
        # manual trigger node mouseover handler
        if node.hasOwnProperty('eventHandlers')
          if node.eventHandlers.hasOwnProperty('mouseover')
            node.eventHandlers.mouseover(this, selection, projection)
        return
      )
    destinationMarkers.exit()
    return
  
  _originDrawCallback: (selection, projection) ->
    self = this
    
    origins = self.getOrigins()
    originCount = origins.length
    if originCount <= 0
      return
    
    count = 0
    lastNode = null
    # select any existing circles and store data onto elements
    originMarkers = selection.selectAll('.origin.marker-icon').data(origins, (node) ->
      count++
      if count == originCount
        lastNode = node
      return node._id
    )
    #work on existing origins (update projection)
    originMarkers
      .attr('x', (node) ->
        x = projection.latLngToLayerPoint(node.latLng).x
        return x - (node.marker.width / projection.scale)
      )
      .attr('y', (node) ->
        y = projection.latLngToLayerPoint(node.latLng).y
        return y - (node.marker.height / projection.scale)
      )
      .attr('width', (node) ->
        return (node.marker.width * 2) / projection.scale
      )
      .attr('height', (node) ->
        return (node.marker.height * 2) / projection.scale
      )
      .sort((a,b) ->
        return d3.descending(a.latLng[0], b.latLng[0])
      )

    # add new elements workflow (following https://github.com/mbostock/d3/wiki/Selections#enter )
    originMarkers.enter().append('image')
      .attr('xlink:href', (node) ->
        href = self.getMarkerHref(node)
        return href
      )
      .attr('x', (node) ->
        x = projection.latLngToLayerPoint(node.latLng).x
        return x - (node.marker.width / projection.scale)
      )
      .attr('y', (node) ->
        y = projection.latLngToLayerPoint(node.latLng).y
        return y - (node.marker.height / projection.scale)
      )
      .attr('width', (node) ->
        return (node.marker.width * 2) / projection.scale
      )
      .attr('height', (node) ->
        return (node.marker.height * 2) / projection.scale
      )
      .attr('class', (node) ->
        return 'origin marker-icon'
      )
      .attr('id', (node) ->
        return self.getElementID(node)
      )
      .sort((a,b) ->
        return d3.descending(a.latLng[0], b.latLng[0])
      )
      .on('click', (node) ->
        d3.event.stopPropagation();
        # manual trigger node click handler
        if node.hasOwnProperty('eventHandlers')
          if node.eventHandlers.hasOwnProperty('click')
            node.eventHandlers.click(this, selection, projection)
        return
      )
      .on('mouseover', (node) ->
        d3.event.stopPropagation();
        # manual trigger node mouseover handler
        if node.hasOwnProperty('eventHandlers')
          if node.eventHandlers.hasOwnProperty('mouseover')
            node.eventHandlers.mouseover(this, selection, projection)
        return
      )
    originMarkers.exit()    
    return

  _projectCX: (projection, node) ->
    x = projection.latLngToLayerPoint(node.latLng).x
    r = (1/projection.scale)
    return x - r

  _projectCY: (projection, node) ->
    y = projection.latLngToLayerPoint(node.latLng).y
    r = (1/projection.scale)
    return y - r

  # converts domain specific flight data into generic GritsNode nodes
  #
  # @param [Object] flight, an Astronomy class 'Flight' represending a single record from a MongoDB collection
  # @param [Array] list of queryOrigins (_id) from the query that should be exclude from the throughput
  # @return [Array] array containing the [originNode, destinationNode]
  convertFlight: (flight, level, queryOrigins) ->
    self = this
    originNode = null
    destinationNode = null
    # the departureAirport of the flight
    origin = flight.departureAirport
    if (typeof origin != "undefined" and origin != null and origin.hasOwnProperty('_id'))
      originNode = self._data[origin._id]
      if (typeof originNode == "undefined" or originNode == null)
        try
          marker = new GritsMarker(_size[0], _size[1], _colorScale)
          originNode = new GritsNode(origin, marker)
          originNode.level = level
          originNode.setEventHandlers(_eventHandlers)
          originNode.outgoingThroughput = flight.totalSeats
          if originNode._id in queryOrigins
            originNode.isOrigin = true
        catch e
          console.error(e.message)
          return
        self._data[origin._id] = originNode
      else
        originNode.outgoingThroughput += flight.totalSeats

    # the arrivalAirport of the flight
    destination = flight.arrivalAirport
    if (typeof destination != "undefined" and destination != null and destination.hasOwnProperty('_id'))
      destinationNode = self._data[destination._id]
      if (typeof destinationNode == "undefined" or destinationNode == null)
        try
          marker = new GritsMarker(_size[0], _size[1], _colorScale)
          destinationNode = new GritsNode(destination, marker)
          destinationNode.level = level
          destinationNode.setEventHandlers(_eventHandlers)
          destinationNode.incomingThroughput = flight.totalSeats
        catch e
          console.error(e.message)
          return
        self._data[destination._id] = destinationNode
      else
        destinationNode.incomingThroughput += flight.totalSeats

    return [originNode, destinationNode]

  # returns the normalized throughput for a node
  #
  # @return [Number] normalizedThroughput, 0 >= n <= .9
  _getNormalizedThroughput: (node) ->
    maxAllowed = 100
    r = 0
    if @_normalizedCI > 0
      r = ((node.incomingThroughput + node.outgoingThroughput) / @_normalizedCI) * 100
    if r > maxAllowed
      return maxAllowed
    node.normalizedPercent = +(r).toFixed(0)
    return node.normalizedPercent

  # returns the color to use as the marker fill
  #
  # @return [String] color, the marker image color
  _getNormalizedColor: (node) ->
    np = @_getNormalizedThroughput(node)
    if np < 10
      node.color = _colorScale[10]
    else if np < 20
      node.color = _colorScale[20]
    else if np < 30
      node.color = _colorScale[30]
    else if np < 40
      node.color = _colorScale[40]
    else if np < 50
      node.color = _colorScale[50]
    else if np < 60
      node.color = _colorScale[60]
    else if np < 70
      node.color = _colorScale[70]
    else if np < 80
      node.color = _colorScale[80]
    else if np < 90
      node.color = _colorScale[90]
    else if np <= 100
      node.color = _colorScale[100]
    else
      node.color = _colorScale[10]
    return node.color

  filterByMinMaxThroughput: (min, max) ->
    self = this
    nodes = self.getNodes()
    if _.isEmpty(nodes)
      return
    filtered = _.filter(nodes, (node) ->
      $element = $('#' + node.elementID)
      np = self._getNormalizedThroughput(node)
      if (np < min) || (np > max)
        $element.css({'display': 'none'})
        n = node
      else
        $element.css({'display': ''})
      if n
        return n
    )
    return filtered
  
  getMarkerHref: (node) ->
    if node.isOrigin
      return '/packages/grits_grits-net-meteor/client/images/origin-marker-icon.svg'
    else
      return ''

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

# Static reference to the colorScale
GritsNodeLayer.colorScale = _colorScale
