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
  @Points = new (Meteor.Collection)(null)
  @layer = L.heatLayer([], {radius: 35, blur: 55, max: 1.0})
  @layerGroup = L.layerGroup([@layer])
  Meteor.gritsUtil.addOverlayControl(@name, @layerGroup)
  @_bindEvents()
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
# level minus the urrent zoom level.
GritsHeatmap::_getZoomFactor = () ->
  (Meteor.gritsUtil.map.getMaxZoom() - Meteor.gritsUtil.map.getZoom()) * 5
# _frequency
#
# Calculates the frequency (intensity) of each node based on all nodes within
# the collection.
GritsHeatmap::_frequency = () ->
  self = this
  total = self.Points.find().count()
  if total == 0
    return
  self.Points.find().forEach (point) ->
    point.frequency = (point.count / total) * self._getCellSize() * self._getZoomFactor()
    point.data = [point.latitude, point.longitude, point.frequency]
    self.Points.update(point._id, point)
# convertFlightDestinationsToPoints
#
# Converts the localFlights minimongo cursor into points for the heatmap plugin
# @param cursor, minimongo cursor of Flights
GritsHeatmap::convertFlightDestinationsToPoints = (cursor) ->
  self = this
  cursor.forEach (flight) ->
    longitude = flight.departureAirport.loc.coordinates[0]
    latitude = flight.departureAirport.loc.coordinates[1]
    _id = CryptoJS.MD5(longitude.toString() + latitude.toString()).toString()
    existing = self.Points.findOne(_id: _id)
    if _.isUndefined(existing)
      self.Points.insert
        _id: _id
        longitude: longitude
        latitude: latitude
        count: 1
    else
      count = existing.count + 1
      self.Points.update({_id: _id}, {longitude: existing.longitude, latitude: existing.latitude, count: count})
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
  if @Points.find().count() == 0
    throw new Error 'The heatmap does not contain any points'
    return

  @_frequency()
  points = @Points.find({}, {fields: {data: 1}}).fetch();
  pointData = _.pluck(points, 'data')
  console.log 'draw::layer.setLatLngs'
  @layer.setLatLngs(pointData)
# clear
#
# Clears the data from the heatmap plugin and updates the heatmap
GritsHeatmap::clear = () ->
  @Points.remove({});
  @layer.setLatLngs([])
