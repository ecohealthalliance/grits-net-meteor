# GritsPath
#
# Creates an instance of a path
GritsPath = (obj, throughput, level, origin, destination) ->
  @_name = 'GritsPath'

  if typeof obj == 'undefined' or !(obj instanceof Object)
    throw new Error("#{@_name} - obj must be defined and of type Object")
    return

  if obj.hasOwnProperty('_id') == false
    throw new Error("#{@_name} - obj requires the _id property")
    return

  if typeof throughput == 'undefined'
    throw new Error("#{@_name} - throughput must be defined")
    return

  if typeof level == 'undefined'
    throw new Error("#{@_name} - level must be defined")
    return

  if (typeof origin == 'undefined' or !(origin instanceof GritsNode))
    throw new Error("#{@_name} - origin must be defined and of type GritsNode")
    return

  if (typeof origin == 'undefined' or !(destination instanceof GritsNode))
    throw new Error("#{@_name} - destination must be defined and of type GritsNode")
    return

  # a unique path is defined as an origin to a destination
  @_id = CryptoJS.MD5(origin._id + destination._id).toString()

  @level = level
  @throughput = throughput

  @normalizedPercent = 0
  @occurrances = 1

  @origin = origin
  @destination = destination
  @midPoint = @getMidPoint()

  @metadata = {}
  _.extend(@metadata, obj)

  return


GritsPath::getMidPoint = () ->
    ud = true
    midPoint = []
    latDif = Math.abs(@origin.latLng[0] - @destination.latLng[0])
    lngDif = Math.abs(@origin.latLng[1] - @destination.latLng[1])
    ud = if latDif > lngDif then false else true
    if @origin.latLng[0] > @destination.latLng[0]
      if ud
        midPoint[0] = @destination.latLng[0] + (latDif / 4)
      else
        midPoint[0] = @origin.latLng[0] - (latDif / 4)
    else
      if ud
        midPoint[0] = @destination.latLng[0] - (latDif / 4)
      else
        midPoint[0] = @origin.latLng[0] + (latDif / 4)
    midPoint[1] = (@origin.latLng[1] + @destination.latLng[1]) / 2
    return midPoint

# GritsPathLayer
#
# Creates an instance of a path 'svg' layer.
GritsPathLayer = (options) ->
  @_name = 'GritsPathLayer'
  @Paths = {}

  @currentPath = null
  @normalizedCI = 0

  if typeof options == 'undefined' or options == null
    @options = {}
  else
    @options = options

  @layer = null
  @layerGroup = null
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
  if !(typeof @layerGroup == 'undefined' or @layerGroup == null)
    Meteor.gritsUtil.map.removeLayer(@layerGroup)
  @layer = null
  @layerGroup = null
  return
# add
#
# adds the heatmap layerGroup to the map
GritsPathLayer::addLayer = () ->
  @layer = L.d3SvgOverlay(_.bind(@drawCallback, this), @options)
  @layerGroup = L.layerGroup([@layer])
  Meteor.gritsUtil.addOverlayControl(@_name, @layerGroup)
  Meteor.gritsUtil.map.addLayer(@layerGroup)
  return
# drawCallback
#
# Note: makes used of _.bind within the constructor so 'this' is encapsulated
# properly
GritsPathLayer::drawCallback = (selection, projection) ->
  self = this

  paths = _.sortBy(_.values(@Paths, (path) ->
    return path.destination.latLng[0]
  ))

  pathCount = paths.length
  if pathCount <= 0
    return

  lines = selection.selectAll('path').data(paths, (path) -> path._id)
  #work on existing nodes
  lines
    .attr('d', (path) ->
      d = []
      d[0] = {}
      d[0].x = projection.latLngToLayerPoint(path.origin.latLng).x
      d[0].y = projection.latLngToLayerPoint(path.origin.latLng).y

      d[1] = {}
      d[1].x = projection.latLngToLayerPoint(path.midPoint).x
      d[1].y = projection.latLngToLayerPoint(path.midPoint).y

      d[2] = {}
      d[2].x = projection.latLngToLayerPoint(path.destination.latLng).x
      d[2].y = projection.latLngToLayerPoint(path.destination.latLng).y

      newLineFunction = d3.svg.line().x((d) ->
        d.x).y((d) ->
          d.y
          ).interpolate('basis')
      newLine = newLineFunction(d)
      return newLine
    ).attr('stroke-width', (path) ->
      weight = self.getWeight(path)
      return weight / projection.scale
    ).attr("stroke", (path) ->
      if path.clicked
        return 'blue'
      self.getStyle(path)
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
      d3.select(this).each ->
        @parentNode.appendChild this
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
    ).enter()
  lines.enter().append('path')
    .attr('d', (path) ->
      d = []
      d[0] = {}
      d[0].x = projection.latLngToLayerPoint(path.origin.latLng).x
      d[0].y = projection.latLngToLayerPoint(path.origin.latLng).y

      d[1] = {}
      d[1].x = projection.latLngToLayerPoint(path.midPoint).x
      d[1].y = projection.latLngToLayerPoint(path.midPoint).y

      d[2] = {}
      d[2].x = projection.latLngToLayerPoint(path.destination.latLng).x
      d[2].y = projection.latLngToLayerPoint(path.destination.latLng).y

      newLineFunction = d3.svg.line().x((d) ->
        d.x).y((d) ->
          d.y
          ).interpolate('basis')
      newLine = newLineFunction(d)
      return newLine
    ).attr('stroke-width', (path) ->
      weight = self.getWeight(path)
      weight / projection.scale
    ).attr("stroke", (path) ->
      if path.clicked
        return 'blue'
      self.getStyle(path)
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
      d3.select(this).each ->
        @parentNode.appendChild this
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
  if Object.keys(@Paths).lenght <= 0
    return
  @layer.draw()
  return

# clear
#
# Clears the Paths from collection
GritsPathLayer::clear = () ->
  @Paths = {}
  @removeLayer()
  @addLayer()

GritsPathLayer::getWeight = (path) ->
  path.weight = path.throughput / 250  + 2

GritsPathLayer::getStyle = (path) ->
  color = '#fef0d9'
  if @normalizedCI > 0
    x = path.throughput / @normalizedCI
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
  return color

# convertFlight
#
# convert a single flight record into a path
GritsPathLayer::convertFlight = (flight, level, origin, destination) ->
  self = this
  if typeof flight == 'undefined' or flight == null
    return

  if typeof level == 'undefined'
    level = 0

  _id = CryptoJS.MD5(origin._id + destination._id).toString()
  path = self.Paths[_id]
  if (typeof path == 'undefined' or path == null)
    path = new GritsPath(flight, flight.totalSeats, level, origin, destination)
    self.Paths[path._id] = path
  else
    path.level = level
    path.occurrances += 1
    path.throughput += flight.totalSeats

  if path.throughput > @normalizedCI
    @normalizedCI = path.throughput
