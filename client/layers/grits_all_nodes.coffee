_eventHandlers = {
  mouseover: (element, selection, projection) ->
    self = this
    map = Template.gritsMap.getInstance()
    nodeLayer = map.getGritsLayer('Nodes')
    if not Session.get('grits-net-meteor:isUpdating')
      # set nodeLayer previous/current node
      nodeLayer.currentNode.set(self)

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
          return
        else
          # erase any previous departures
          GritsFilterCriteria.setDepartures(null)
          # set the clicked element as the new origin
          departureSearchMain = Template.gritsFilter.getDepartureSearchMain()
          departureSearchMain.tokenfield('setTokens', [self._id])

          async.nextTick(() ->
            # apply the filter
            GritsFilterCriteria.apply((err, res) ->
              if res
                map = Template.gritsMap.getInstance()
                pathLayer = map.getGritsLayer('Paths')
                nodeLayer = map.getGritsLayer('Nodes')
                if map.getZoom() > 2
                  # panto the map if we're at zoom level 3 or greater
                  map.panTo(self.latLng)
                else
                  # set the view to the latLng and zoom level to 2
                  map.setView(self.latLng, 2)
                # reset the current path
                pathLayer.currentPath.set(null)
                # set nodeLayer previous/current node
                nodeLayer.currentNode.set(self)
            )
          )
    return
}
# custom [width, height] size for each marker
_size = [7, 7]

# Creates an instance of a GritsAllNodesLayer, extends  GritsLayer
#
# @param [Object] map, an instance of GritsMap
# @param [String] displayName, the displayName for the layer selector
class GritsAllNodesLayer extends GritsLayer
  constructor: (map, displayName) ->
    GritsLayer.call(this) # invoke super constructor
    self = this

    if typeof map == 'undefined'
      throw new Error('A layer requires a map to be defined')
      return
    if !map instanceof GritsMap
      throw new Error('A layer requires a valid map instance')
      return
    if typeof displayName == 'undefined'
      self._displayName = 'All Nodes'
    else
      self._displayName = displayName

    self._name = 'AllNodes'
    self._map = map

    self._layer = L.d3SvgOverlay(_.bind(self._drawCallback, this), {})
    self._layerGroup = L.layerGroup([self._layer])
    self._map.addOverlayControl(self._displayName, @_layerGroup)

    self._prefixDOMID = 'all-node-'

    self.hasLoaded = new ReactiveVar(false)

    self._bindMapEvents()
    self._populateAllNodes()
    return

  # clears the layer
  #
  # @override
  clear: () ->
    @_removeLayerGroup()
    @_addLayerGroup()
    @hasLoaded.set(false)

  # draws the layer
  #
  # @override
  draw: () ->
    self = this
    self._layer.draw()
    return

  # gets the nodes from the layer
  #
  # @return [Array] array of nodes
  getNodes: () ->
    return _.values(@_data)

  # gets the element ID within the DOM of a path
  #
  # @param [Object] obj, a gritsNode object
  # @return [String] elementID
  getElementID: (obj) ->
    return @_prefixDOMID + obj._id

  # The D3 callback that renders the svg elements on the map
  #
  # @see https://github.com/mbostock/d3/wiki/API-Reference
  # @see https://github.com/mbostock/d3/wiki/Selections
  # @param [Object] selection, the array of elements pulled from the current document, also includes helper methods for filtering similar to jQuery
  # @param [Object] projection, the current scale
  _drawCallback: (selection, projection) ->
    self = this

    nodes = self.getNodes()
    nodeCount = nodes.length
    if nodeCount <= 0
      return

    # select any existing circles and store data onto elements
    markers = selection.selectAll('.all-nodes.marker-icon').data(nodes, (node) ->
      node._id
    )

    #work on existing nodes
    markers
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
        return '#333333'
      )
      .attr('fill-opacity', .5)
      .sort((a,b) ->
        return d3.descending(a.latLng[0], b.latLng[0])
      )

    # add new elements workflow (following https://github.com/mbostock/d3/wiki/Selections#enter )
    markers.enter().append('circle')
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
        return '#333333';
      )
      .attr('fill-opacity', .5)
      .attr('class', (node) ->
        return 'all-nodes marker-icon'
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
    markers.exit()
    return

  _projectCX: (projection, node) ->
    x = projection.latLngToLayerPoint(node.latLng).x
    r = (1/projection.scale)
    return x - r

  _projectCY: (projection, node) ->
    y = projection.latLngToLayerPoint(node.latLng).y
    r = (1/projection.scale)
    return y - r

  # populates all nodes from the database
  _populateAllNodes: () ->
    self = this
    Meteor.call('findAirports', (err, airports) ->
      if err
        console.error(err)
        return

      count = 0
      total = airports.length
      processQueue = async.queue(((airport, callback) ->
        async.nextTick ->
          try
            marker = new GritsMarker(_size[0], _size[1], null)
            node = new GritsNode(airport, marker)
            node.setEventHandlers(_eventHandlers)
            self._data[airport._id] = node
          catch err
            console.error(err)

          count++
          if !(count % 100)
            if Meteor.gritsUtil.debug
              console.log("all nodes: #{count} of #{total}")
          if count == total
            console.log("all nodes: #{count} of #{total}")
          callback()
      ), 1)

      processQueue.drain = () ->
        self.hasLoaded.set(true)

      processQueue.push(airports)
      return
    )
    return

  # binds to the Tracker.gritsMap.getInstance() map event listener .on
  # 'overlyadd' and 'overlayremove' methods
  _bindMapEvents: () ->
    self = this
    if typeof self._map == 'undefined'
      return
    self._map.on(
      overlayadd: (e) ->
        if e.name == self._displayName
          if !self.hasLoaded.get()
            toastr.warning('The layer has not finished loading')
            return
          if Meteor.gritsUtil.debug
            console.log("#{self._displayName} layer was added")
      overlayremove: (e) ->
        if e.name == self._displayName
          if Meteor.gritsUtil.debug
            console.log("#{self._displayName} layer was removed")
    )
