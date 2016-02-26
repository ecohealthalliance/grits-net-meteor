_previousOrigins = [] # array to track state of the heatmap
HEATMAP_INTENSITY_MULTIPLIER = 30
# Creates an instance of a GritsHeatmapLayer, extends  GritsLayer
#
# @param [Object] map, an instance of GritsMap
# @param [String] displayName, the displayName for the layer selector
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

    self._layer = new L.TileLayer.WebGLHeatMap(
      size: 1609.34 * 250 # meters equals 250 miles
      alphaRange: 0.1
      gradientTexture: "/packages/grits_grits-net-meteor/client/images/viridis.png"
      opacity: 0.75
    )

    self.hasLoaded = new ReactiveVar(false)

    self._bindMapEvents()
    self._trackDepartures()
    return

  # The heatmap library's gradient doesn't load until the map moves
  # so this moves the map slightly to make it load.
  _perturbMap: ()->
    currentCenter = @_map.getCenter()
    @_map.setView(
      lat: currentCenter.lat + 1
      lng: currentCenter.lng + 1
    )
    @_map.setView(currentCenter)

  # draws the heatmap
  #
  # @note method overrides the parent class GritsLayer clear method
  # @override
  draw: () ->
    self = this
    data = self._data.map((d)->
      [d[0], d[1], d[2] * HEATMAP_INTENSITY_MULTIPLIER]
    )
    # An extra point with no intensity is added because passing in an empty
    # array causes a bug where the previous heatmap is frozen in view.
    self._layer.setData(data.concat([[0.0, 0.0, 0.0]]))
    self._perturbMap()
    self.hasLoaded.set(true)
    return

  # clears the heatmap
  #
  # @note method overrides the parent class GritsLayer clear method
  # @override
  clear: () ->
    self = this
    self._data = []
    self._layer.setData(self._data)
    self.hasLoaded.set(false)
    return

  # setup a Meteor Tracker.autorun function to watch the global reactive var
  # departures.
  _trackDepartures: () ->
    self = this
    Tracker.autorun () ->
      departures = GritsFilterCriteria.departures.get()

      if _.isEmpty(departures)
        # if a departure airport is not specified, clear the heatmap
        _previousOrigins = null
        self.clear()
        self.draw()
        return

      # handle any metaNodes
      modifiedDepartures = []
      _.each(departures, (token) ->
        if (token.indexOf(GritsMetaNode.PREFIX) >= 0)
          node = GritsMetaNode.find(token)
          if node == null
            return
          if (node.hasOwnProperty('_children'))
            modifiedDepartures = _.union(modifiedDepartures, _.pluck(node._children, '_id'))
        else
          modifiedDepartures = _.union(modifiedDepartures, token)
      )
      departures = modifiedDepartures

      # update the heatmap data
      heatmap = Heatmaps.findOne({'_id': departures.sort().join("") })
      self.clear()
      self._data = heatmap?.data or []
      self.draw()

      _previousOrigins = departures
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
        self._perturbMap()
      overlayremove: (e) ->
        if e.name == self._displayName
          if Meteor.gritsUtil.debug
            console.log("#{self._displayName} layer was removed")
    )
