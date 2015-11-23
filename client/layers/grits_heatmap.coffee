GritsHeatmapLayer = (map) ->
  GritsLayer.call(this)
  
  if typeof map == 'undefined'
    throw new Error('A layer requires a map to be defined')
    return
  if !map instanceof GritsMap
    throw new Error('A layer requires a valid map instance')
    return
  
  @_name = 'Heatmap'
  @_map = map  
  @_data = []
  
  @_layer = L.heatLayer([], {radius: 35, blur: 55})
  @_layerGroup = L.layerGroup([@_layer])
  @_map.addOverlayControl(@_name, @_layerGroup)
  
  @_bindMapEvents()
  @_trackDepartures()
  return
  
GritsHeatmapLayer.prototype = Object.create(GritsLayer.prototype)
GritsHeatmapLayer.prototype.constructor = GritsHeatmapLayer

#
#
# override
GritsHeatmapLayer::draw = () ->
  if @_data.length == 0
    return
  @_layer.setLatLngs(@_data)

#
#
# override
GritsHeatmapLayer::clear = () ->
  @_data = []
  @_layer.setLatLngs(@_data)  

# _getCellSize
#
# Leaflet.Heat uses a cell size to 'blend' points into a cluster.
# returns  the cellSize
GritsHeatmapLayer::_getCellSize = () ->
  cellSize = 100
  if @_layer.hasOwnProperty('options') and @_layer.options.hasOwnProperty('radius')
    cellSize = @_layer.options.radius * 4
  cellSize

# _getZoomFactor
#
# Determine the zoomFactor, which is a multiplier based on the maximum zoom
# level minus the current zoom level.
GritsHeatmapLayer::_getZoomFactor = () ->
  (@_map.getMap().getMaxZoom() - @_map.getMap().getZoom()) * 5

# _trackDepartures
#
#
GritsHeatmapLayer::_trackDepartures = () ->
  self = this
  Tracker.autorun () ->
    query = Session.get('grits-net-meteor:query')
    if _.isUndefined(query) || _.isNull(query)
      return
    if Session.get('grits-net-meteor:isUpdating') == true
      return
    
    # the filter has a departureAirport identified
    if _.has(query, 'departureAirport._id')
      # the filter has an array of airports 
      if _.has(query['departureAirport._id'], '$in')
        departures = query['departureAirport._id']['$in']
        Meteor.call('findHeatmapByCode', departures[0], (err, res) ->
          if err
            console.error err
            return
                    
          if _.isUndefined(res)
            return
          
          self.clear()
          _.each(res.data, (a) ->
            # if the node exists on the map, add to the heat map
            #node = Meteor.gritsUtil.nodeLayer.Nodes[a[3]]
            #if _.isUndefined(node)
            #  return
            intensity = a[2] * self._getCellSize() * self._getZoomFactor()
            self._data.push([a[0], a[1], intensity])
          )
          self.draw()
        )
    else
      # if a departure airport is not specified, clear the heatmap
      self.clear()

# _bindMapEvents
#
# Binds to the global map.on 'overlyadd' and 'overlayremove' methods
GritsHeatmapLayer::_bindMapEvents = () ->
  self = this
  if typeof self._map.getMap() == 'undefined'
    return  
  self._map.getMap().on(
    overlayadd: (e) ->
      if e.name == self._name
        if Meteor.gritsUtil.debug
          console.log self._name + ' added'
    overlayremove: (e) ->
      if e.name == self._name
        if Meteor.gritsUtil.debug
          console.log self._name + ' removed'
  )