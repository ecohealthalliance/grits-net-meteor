# GritsHeatmap
#
# Creates an instance of a heatmap layer.  Relies on client/grits_util.coffee
# to be placed at a higher order within package.js.  In addition, it cannot be
# constructed until Meteor.gritsUtil.initLeaflet has been called.
#
# Note: these ordering requirements could be avoided through a third-party
# library, such as reactive-depenency, which implements a lightweight dependency
# injection framework.
GritsHeatmap = () ->
  @name = 'Heatmap'
  @Points = []
  @layer = L.heatLayer([], {radius: 35, blur: 55})
  @layerGroup = L.layerGroup([@layer])
  Meteor.gritsUtil.addOverlayControl(@name, @layerGroup)
  @_bindEvents()
  @_trackDepartures()
  return
# _bindEvents
#
# Binds to the global map.on 'overlyadd' and 'overlayremove' methods
GritsHeatmap::_bindEvents = () ->
  self = this
  Meteor.gritsUtil.map.on(
    overlayadd: (e) ->
      if e.name == self.name
        if Meteor.gritsUtil.debug
          console.log self.name + ' added'
    overlayremove: (e) ->
      if e.name == self.name
        if Meteor.gritsUtil.debug
          console.log self.name + ' removed'
  )
# _getCellSize
#
# Leaflet.Heat uses a cell size to 'blend' points into a cluster.
# returns  the cellSize
GritsHeatmap::_getCellSize = () ->
  cellSize = 100
  if @layer.hasOwnProperty('options') and @layer.options.hasOwnProperty('radius')
    cellSize = @layer.options.radius * 4
  cellSize
# _getZoomFactor
#
# Determine the zoomFactor, which is a multiplier based on the maximum zoom
# level minus the current zoom level.
GritsHeatmap::_getZoomFactor = () ->
  (Meteor.gritsUtil.map.getMaxZoom() - Meteor.gritsUtil.map.getZoom()) * 5

GritsHeatmap::_trackDepartures = () ->
  self = this
  Tracker.autorun () ->
    query = Session.get('query')
    if _.isUndefined(query) || _.isNull(query)
      return
    if Session.get('isUpdating') == true
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
          self.clear()
          _.each(res.data, (a) ->
            # if the node exists on the map, add to the heat map
            #node = Meteor.gritsUtil.nodeLayer.Nodes[a[3]]
            #if _.isUndefined(node)
            #  return
            intensity = a[2] * self._getCellSize() * self._getZoomFactor()
            self.Points.push([a[0], a[1], intensity])
          )
          self.draw()
        )
    else
      # if a departure airport is not specified, clear the heatmap
      self.clear()

# remove
#
# removes the heatmap layerGroup from the map
GritsHeatmap::remove = () ->
  Meteor.gritsUtil.map.removeLayer(@layerGroup)
# add
#
# adds the heatmap layerGroup to the map
GritsHeatmap::add = () ->
  Meteor.gritsUtil.addOverlayControl(@name, @layerGroup)
# draw
#
# Sets the data for the heatmap plugin and updates the heatmap
GritsHeatmap::draw = () ->
  if @Points.length == 0
    return
  @layer.setLatLngs(@Points)
# clear
#
# Clears the data from the heatmap plugin and updates the heatmap
GritsHeatmap::clear = () ->
  @Points = []
  @layer.setLatLngs([])
