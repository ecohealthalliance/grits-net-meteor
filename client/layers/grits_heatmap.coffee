# Creates an instance of a GritsHeatmapLayer, extends  GritsLayer
#
# @param [Object] map, an instance of GritsMap
class GritsHeatmapLayer extends GritsLayer
  constructor: (map) ->
    GritsLayer.call(this) # invoke super constructor
    if typeof map == 'undefined'
      throw new Error('A layer requires a map to be defined')
      return
    if !map instanceof GritsMap
      throw new Error('A layer requires a valid map instance')
      return
    
    @_name = 'Heatmap'
    @_map = map  
    @_data = []
    
    @_layer = L.heatLayer([], {radius: 30, blur: 15})
    @_layerGroup = L.layerGroup([@_layer])
    @_map.addOverlayControl(@_name, @_layerGroup)
    
    @hasLoaded = new ReactiveVar(false)
    
    @_bindMapEvents()
    @_trackDepartures()
    return
  
  # draws the heatmap
  #
  # @note method overrides the parent class GritsLayer clear method
  # @override
  draw: () ->
    if @_data.length == 0
      return
    @_layer.setLatLngs(@_data)
    return
  
  # clears the heatmap
  #
  # @note method overrides the parent class GritsLayer clear method
  # @override
  clear: () ->
    @_data = []
    @_layer.setLatLngs(@_data)
    @hasLoaded.set(false)
    return
  
  # returns the cellSize of the Leaflet.Heat plugin
  # @note Leaflet.Heat uses a cell size to 'blend' points into a cluster
  # @return [Integer] cellSize
  _getCellSize: () ->
    cellSize = 100
    if @_layer.hasOwnProperty('options') and @_layer.options.hasOwnProperty('radius')
      cellSize = @_layer.options.radius * 4
    cellSize
  
  # returns the zoomFactor, which is a multiplier based on the maximum zoom
  # level minus the current zoom level.
  #
  # @return [Integer] zoomFactor
  _getZoomFactor: () ->
    (@_map.getMaxZoom() - @_map.getZoom()) * 5
  
  # setup a Meteor Tracker.autorun function to watch the global Session object
  # 'grits-net-meteor:query' to contain departures.  If so, make a server side
  # call to get the heatmap data.  Do this everytime the global query changes.
  _trackDepartures: () ->
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
          Meteor.call('findHeatmapsByCodes', departures, (err, heatmaps) ->
            if err
              console.error err
              return
                      
            if _.isUndefined(heatmaps)
              return
            
            self.clear()
            for heatmap in heatmaps
              _.each(heatmap.data, (a) ->
                intensity = a[2] * self._getCellSize() * self._getZoomFactor()
                self._data.push([a[0], a[1], intensity, a[2], a[3]])
              )
            self.hasLoaded.set(true)
            self.draw()
          )
      else
        # if a departure airport is not specified, clear the heatmap
        self.clear()
  
  # append a single heatmap to the existing layer, does not clear existing data
  #
  # @param [Object] heatmap, Astro.class representation of 'Heatmap' model
  add: (heatmap) ->
    if _.isUndefined(heatmap)
      return
    self = this
    _.each(heatmap.data, (a) ->
      intensity = a[2] * self._getCellSize() * self._getZoomFactor()
      self._data.push([a[0], a[1], intensity])
    )
    self.hasLoaded.set(true)
    self.draw()
    return
  
  # get the heatmap data
  #
  # @return [Array] array of the heatmap data
  getData: () ->
    if _.isEmpty(@_data)
      return []
    return @_data
  
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