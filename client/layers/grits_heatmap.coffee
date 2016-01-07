_previousOrigins = [] # array to track state of the heatmap
# Creates an instance of a GritsHeatmapLayer, extends  GritsLayer
#
# @param [Object] map, an instance of GritsMap
class GritsHeatmapLayer extends GritsLayer
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
      self._displayName = 'Heatmap'
    else
      self._displayName = displayName
    
    self._name = 'Heatmap'
    self._map = map
    self._data = []

    self._layer = L.heatLayer([], {radius: 30, blur: 15, maxZoom: 0})
    self._layerGroup = L.layerGroup([self._layer])
    self._map.addOverlayControl(@_name, self._layerGroup)

    self.hasLoaded = new ReactiveVar(false)

    self._bindMapEvents()
    self._trackDepartures()
    return

  # draws the heatmap
  #
  # @note method overrides the parent class GritsLayer clear method
  # @override
  draw: () ->
    self = this
    self._layer.setLatLngs(self._data)
    self.hasLoaded.set(true)
    return

  # clears the heatmap
  #
  # @note method overrides the parent class GritsLayer clear method
  # @override
  clear: () ->
    self = this
    self._data = []
    self._layer.setLatLngs(self._data)
    self.hasLoaded.set(false)
    return

  # removes the layer
  #
  remove: () ->
    self = this
    self._removeLayerGroup()

  # adds the layer
  #
  add: () ->
    self = this
    self._addLayerGroup()

  # removes the layerGroup from the map
  #
  # @override
  _removeLayerGroup: () ->
    self = this
    if !(typeof self._layerGroup == 'undefined' or self._layerGroup == null)
      self._map.removeLayer(self._layerGroup)
    return

  # adds the layer group to the map
  #
  # @override
  _addLayerGroup: () ->
    self = this
    self._layerGroup = L.layerGroup([self._layer])
    self._map.addOverlayControl(self._displayName, self._layerGroup)
    self._map.addLayer(self._layerGroup)
    return

  # setup a Meteor Tracker.autorun function to watch the global Session object
  # 'grits-net-meteor:query' to contain departures.  If so, make a server side
  # call to get the heatmap data.  Do this everytime the global query changes.
  _trackDepartures: () ->
    self = this
    Tracker.autorun () ->
      departures = GritsFilterCriteria.departures.get()

      if _.isEqual(_previousOrigins, departures)
        # do nothing
        return

      if _.isEmpty(departures)
        # if a departure airport is not specified, clear the heatmap
        _previousOrigins = null
        self.clear()
        self.draw()
        return

      # update the heatmap data
      Meteor.call('findHeatmapsByCodes', departures, (err, heatmaps) ->
        if err
          Meteor.gritsUtil.errorHandler(err)
          return

        self.clear()
        len = heatmaps.length
        for heatmap in heatmaps
          _.each(heatmap.data, (a) ->
            value = a[2]
            if len > 0
              value = value / len
            self._data.push([a[0], a[1], value, a[3]])
          )
        self.draw()
      )
      _previousOrigins = departures
    return

  # append a single heatmap to the existing layer, does not clear existing data
  #
  # @param [Object] heatmap, Astro.class representation of 'Heatmap' model
  add: (heatmap) ->
    self = this
    if _.isUndefined(heatmap)
      return
    _.each(heatmap.data, (a) ->
      intensity = a[2] * self._getCellSize()
      self._data.push([a[0], a[1], intensity])
    )
    self.hasLoaded.set(true)
    self.draw()
    return

  # get the heatmap data
  #
  # @return [Array] array of the heatmap data
  getData: () ->
    self = this
    if _.isEmpty(self._data)
      return []
    return self._data

  # binds to the Tracker.gritsMap.getInstance() map event listener .on
  # 'overlyadd' and 'overlayremove' methods
  _bindMapEvents: () ->
    self = this
    if typeof self._map == 'undefined'
      return
    self._map.on(
      overlayadd: (e) ->
        if e.name == self._displayName
          if Meteor.gritsUtil.debug
            console.log("#{self._displayName} layer was added")
      overlayremove: (e) ->
        if e.name == self._displayName
          if Meteor.gritsUtil.debug
            console.log("#{self._displayName} layer was removed")
    )
