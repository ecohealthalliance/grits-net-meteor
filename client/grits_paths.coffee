# GritsPath
#
# Creates an instance of a node that represents a geoJSON point
GritsPath = (obj) ->
  @obj = obj
  @name = 'Path'
  @_id = obj._id
  @pointList = null
  @midPoint = null
  @pathLine = null
  @origin = null
  @destination = null
  @destWAC = null
  @miles = obj.miles
  @origWAC = obj['Orig WAC']
  @totalSeats = obj.totalSeats
  @seats_week = obj['Seats/Week']
  @stops = obj.Stops
  @flights = 0
  @visible = false
  @normalizedPercent = 0
  @level = obj.level
  if obj.departureAirport != null
    obj.departureAirport.level = obj.level
    @departureAirport = new GritsNode(obj.departureAirport)
  if obj.arrivalAirport != null
    obj.arrivalAirport.level = obj.level
    @arrivalAirport = new GritsNode(obj.arrivalAirport)
  @pointList = [
    new (L.LatLng)(@departureAirport.latLng[0], @departureAirport.latLng[1]),
    new (L.LatLng)(@arrivalAirport.latLng[0], @arrivalAirport.latLng[1])
  ]
  @show= ->
    @visible = true
    # hide arrival/dest nodes if no other path touches them
    return
  @hide= ->
    @visible = false
    return
  @getMidPoint = ->
    points = @pointList
    ud = true
    midPoint = []
    latDif = Math.abs(points[0].lat - (points[1].lat))
    lngDif = Math.abs(points[0].lng - (points[1].lng))
    ud = if latDif > lngDif then false else true
    if points[0].lat > points[1].lat
      if ud
        midPoint[0] = points[1].lat + (latDif / 4)
      else
        midPoint[0] = points[0].lat - (latDif / 4)
    else
      if ud
        midPoint[0] = points[1].lat - (latDif / 4)
      else
        midPoint[0] = points[0].lat + (latDif / 4)
    midPoint[1] = (points[0].lng + points[1].lng) / 2
    return new (L.LatLng)(midPoint[0], midPoint[1])
  # @note redraw the path
  @refresh= ->
    @hide()
    @show()
  # @note Set the color and weight of the path
  #
  # @param [String] color - color of the path
  # @param [Float] weight - weight of the path (pixels)
  @setStyle= (color, weight) ->
    @color = color
    @weight = weight
    @refresh()
  @midPoint = @getMidPoint()
  return this
# GritsPathLayer
#
# Creates an instance of a path 'svg' layer.
GritsPathLayer = (options) ->
  @_name = 'Path'
  @Paths = new (Meteor.Collection)(null)
  @currentPath = null

  if typeof options == 'undefined' or options == null
    @options = {}
  else
    @options = options

  @layer = L.d3SvgOverlay(_.bind(@drawCallback, this), options)
  @layerGroup = L.layerGroup([@layer])
  Meteor.gritsUtil.addOverlayControl(@_name, @layerGroup)
  @_bindEvents()
  return
# _bindEvents
#
# Binds to the global map.on 'overlyadd' and 'overlayremove' methods
GritsPathLayer::_bindEvents = () ->
  self = this
  Meteor.gritsUtil.map.on(
    overlayadd: (e) ->
      if e.name == self._name
        if Meteor.gritsUtil.debug
          console.log self._name + ' added'
    overlayremove: (e) ->
      if e.name == self._name
        if Meteor.gritsUtil.debug
          console.log self._name + ' removed'
  )
# remove
#
# removes the heatmap layerGroup from the map
GritsPathLayer::removeLayer = () ->
  Meteor.gritsUtil.map.removeLayer(@layerGroup)
  return
# add
#
# adds the heatmap layerGroup to the map
GritsPathLayer::addLayer = () ->
  Meteor.gritsUtil.map.addLayer(@layerGroup)
  return
# drawCallback
#
# Note: makes used of _.bind within the constructor so 'this' is encapsulated
# properly
GritsPathLayer::drawCallback = (selection, projection) ->
  pathCount = @Paths.find().count()
  if pathCount <= 0
    return
  paths = @Paths.find({}).fetch()
  lines = selection.selectAll('path').data(paths, (path) -> path._id)
  #work on existing nodes
  lines
    .attr('d', (path) ->
      d = []
      d[0] = {}
      d[0].x = projection.latLngToLayerPoint(new L.LatLng(path.departureAirport.latLng[0],path.departureAirport.latLng[1])).x
      d[0].y = projection.latLngToLayerPoint(new L.LatLng(path.departureAirport.latLng[0],path.departureAirport.latLng[1])).y

      d[1] = {}
      d[1].x = projection.latLngToLayerPoint(path.midPoint).x
      d[1].y = projection.latLngToLayerPoint(path.midPoint).y

      d[2] = {}
      d[2].x = projection.latLngToLayerPoint(new L.LatLng(path.arrivalAirport.latLng[0],path.arrivalAirport.latLng[1])).x
      d[2].y = projection.latLngToLayerPoint(new L.LatLng(path.arrivalAirport.latLng[0],path.arrivalAirport.latLng[1])).y

      newLineFunction = d3.svg.line().x((d) ->
        d.x).y((d) ->
          d.y
          ).interpolate('basis')
      newLine = newLineFunction(d)
      return newLine
    ).attr('stroke-width', (path) ->
      path.weight / projection.scale
    ).attr("stroke", (path) ->
      if path.clicked
        return 'blue'
      return path.color
    ).attr("fill", "none")
    .on('mouseover', (path) ->
      if path.clicked
        d3.select(this).style("cursor": "pointer")
        return
      d3.select(this).style('stroke', 'black')
      .style("cursor": "pointer")
      return
    ).on('mouseout', (path) ->
      if path.clicked
        d3.select(this).style("cursor": "hand")
        return
      d3.select(this).style('stroke', path.color)
      .style("cursor": "hand")
      return
    ).on('click', (path)->
      if path.clicked
        pathHandler.unClick(path)
        d3.select(this).style('stroke', 'black')
        return
      this.id = path._id
      d3.select(this).style('stroke', 'blue')
      oldPath = pathHandler.getCurrentPath()
      pathHandler.setCurrentPath(this)
      if oldPath isnt null
        d3p = d3.select(oldPath)
        oldPath.__data__.clicked = false
        d3p.style('stroke', oldPath.__data__.color)
      pathHandler.click(path)
      return
    )
  lines.enter().append('path')
    .attr('d', (path) ->
      d = []
      d[0] = {}
      d[0].x = projection.latLngToLayerPoint(new L.LatLng(path.departureAirport.latLng[0],path.departureAirport.latLng[1])).x
      d[0].y = projection.latLngToLayerPoint(new L.LatLng(path.departureAirport.latLng[0],path.departureAirport.latLng[1])).y

      d[1] = {}
      d[1].x = projection.latLngToLayerPoint(path.midPoint).x
      d[1].y = projection.latLngToLayerPoint(path.midPoint).y

      d[2] = {}
      d[2].x = projection.latLngToLayerPoint(new L.LatLng(path.arrivalAirport.latLng[0],path.arrivalAirport.latLng[1])).x
      d[2].y = projection.latLngToLayerPoint(new L.LatLng(path.arrivalAirport.latLng[0],path.arrivalAirport.latLng[1])).y

      newLineFunction = d3.svg.line().x((d) ->
        d.x).y((d) ->
          d.y
          ).interpolate('basis')
      newLine = newLineFunction(d)
      return newLine
    ).attr('stroke-width', (path) ->
      path.weight / projection.scale
    ).attr("stroke", (path) ->
      if path.clicked
        return 'blue'
      return path.color
    ).attr("fill", "none")
    .on('mouseover', (path) ->
      if path.clicked
        d3.select(this).style("cursor": "pointer")
        return
      d3.select(this).style('stroke', 'black')
      .style("cursor": "pointer")
      return
    ).on('mouseout', (path) ->
      if path.clicked
        d3.select(this).style("cursor": "hand")
        return
      d3.select(this).style('stroke', path.color)
      .style("cursor": "hand")
      return
    ).on('click', (path)->
      if path.clicked
        pathHandler.unClick(path)
        d3.select(this).style('stroke', 'black')
        return
      this.id = path._id
      d3.select(this).style('stroke', 'blue')
      oldPath = pathHandler.getCurrentPath()
      pathHandler.setCurrentPath(this)
      if oldPath isnt null
        d3p = d3.select(oldPath)
        oldPath.__data__.clicked = false
        d3p.style('stroke', oldPath.__data__.color)
      pathHandler.click(path)
      return
    )
  lines.exit()
  return

# draw
#
# Sets the data for the heatmap plugin and updates the heatmap
GritsPathLayer::draw = () ->
  if @Paths.find().count() == 0
    throw new Error 'The layer does not contain any paths'
    return
  @removeLayer()
  @addLayer()
  return

# clear
#
# Clears the Paths from collection
GritsPathLayer::clear = () ->
  @Paths.remove({});
  @removeLayer()
  @addLayer()
GritsPathLayer::addPath = (path) ->
  @Paths.upsert(path._id, path)
GritsPathLayer::removePath = (path) ->
  @Paths.remove(path._id)
# convertFlightsToPaths
#
# Helper method that converts the localFlights minimongo cursor into a
# set of paths
# @param cursor, minimongo cursor of Flights
GritsPathLayer::convertFlightToPaths = (cursor, cb) ->
  self = this
  self.normalizedCI = 0
  count = 0
  cursorCount = cursor.count()

  cursor.forEach((flight) ->
    setTimeout(() ->
      if typeof flight != "undefined" and flight != null
        path = GritsPaths.getGritsPathByFactor(flight)
        if typeof path is null
          try
            path = new GritsPath(flight)
            self.addPath(path)
            GritsPaths.addFactor(flight)
          catch e
            console.error(e.message)
            return
        else
          path = GritsPaths.addFactor(flight);

        if path.totalSeats > self.normalizedCI
          self.normalizedCI = path.totalSeats
    , 0)
  )

  cursor.forEach((flight) ->
    setTimeout(() ->
      if typeof flight != "undefined" and flight != null
        path = GritsPaths.getGritsPathByFactor(flight)
        if typeof path is null
          try
            path = new GritsPath(flight)
            self.addPath(path)
            GritsPaths.addFactor(flight)
          catch e
            console.error(e.message)
            return
        else
          path = GritsPaths.addFactor(flight);
        if path isnt false
          x = path.totalSeats / self.normalizedCI
          np = parseFloat(1-(1 - x))
          path.normalizedPercent = np
          if np < .20
            color = '#fef0d9'
          else if np < .40
            color = '#fdcc8a'
          else if np < .60
            color = '#fc8d59'
          else if np < .80
            color = '#e34a33'
          else if np <= 1
            color = '#b30000'
          weight = path.totalSeats / 250  + 2
          path.setStyle(color, weight)
          self.addPath(path)
      if cursorCount == ++count
        cb(null, true)
    , 0)
  )

GritsPaths =
  gritsPaths : []
  factors : []
  resetLevels: () ->
    for path in @gritsPaths
      path.level = 0
      path.arrivalAirport.level = 0
      path.departureAirport.level = 0
  getPathByPathLine: (pathId) ->
    for path in @gritsPaths
      if path.pathLine._leaflet_id is pathId
        return path
    return false
  getLayerGroup: ->
    L.layerGroup @gritsPaths
  # @note finds and returns the factor by factorId if it exists
  #
  # @param [String] id - Id of factor to be retrieved
  getFactorById: (id) ->
    factor = undefined
    i = undefined
    len = undefined
    ref = undefined
    ref = @factors
    i = 0
    len = ref.length
    while i < len
      factor = ref[i]
      if factor._id == id
        return factor
      i++
    false
  # @note finds and returns the MapPath by factor departure and arrival
  #       airport if it exists
  #
  # @param [JSON] factor - flight data
  getGritsPathByFactor: (factor) ->
    i = undefined
    len = undefined
    ref = undefined
    tempMapPath = undefined
    ref = @gritsPaths
    i = 0
    len = ref.length
    while i < len
      tempMapPath = ref[i]
      if tempMapPath.departureAirport._id == factor['departureAirport']._id and tempMapPath.arrivalAirport._id == factor['arrivalAirport']._id
        return tempMapPath
      i++
    false
  # @note adds a new MapPath to GritsPaths.gritsPaths
  #
  # @param [MapPath] mapPath
  addInitializedPath: (mapPath) ->
    @gritsPaths.push mapPath
  # @note adds a new factor to GritsPaths.factors
  #
  # @param [JSON] factor - flight data
  addFactor: (factor) ->
    existingFactor = @getFactorById(factor._id)
    if existingFactor != false
      return @getGritsPathByFactor(existingFactor)
    path = @getGritsPathByFactor(factor)
    if path != false
      path.totalSeats += factor['totalSeats']
    else if path == false
      path = new GritsPath(factor)
    @factors.push factor
    path.flights++
    @gritsPaths.push path
    return path
  # @note removes a factor by id from GritsPaths.factors
  #
  # @param [String] id - Id of factor to be removed
  removeFactor: (id) ->
    factor = undefined
    path = undefined
    ref = undefined
    factor = @getFactorById(id)
    if factor == false
      return false
    @factors.splice @factors.indexOf(factor), 1
    path = @getMapPathByFactor(factor)
    path.totalSeats -= factor['totalSeats']
    path.flights--
    if path.flights is 0
      path.hide()
      #MapNodes.checkAndHideNodes(path)
      return false
    else
      return {
        'path': path
        'factor': factor
      }
  # @note update an existing factor in GritsPaths.factors
  #
  # @param [String] id - Id of factor to be updated
  # @param [JSON] newFactor - updated flight data
  # @param [L.Map] map
  updateFactor: (id, newFactor, map, level) ->
    oldFactor = @getFactorById(id)
    if !oldFactor
      return false
    path = @getMapPathByFactor(oldFactor)
    path.level = level
    path.totalSeats -= oldFactor['totalSeats']
    path.totalSeats += newFactor['totalSeats']
    #TODO: What else needs to be updated?  seats_week?
    return path
  showPath: (mapPath) ->
    mapPath.show()
  hidePath: (mapPath) ->
    mapPath.hide()
