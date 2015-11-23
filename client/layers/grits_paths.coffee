_eventHandlers = {
  mouseout: (element, selection, projection) ->
    if not Session.get('grits-net-meteor:isUpdating')
      oldPath = Template.gritsMap.currentPath # initialized to null
      if oldPath isnt null
        if element is oldPath.element
          d3.select(element).style("cursor": "pointer")
          return
      d3.select(element).style('stroke', @color).style("cursor": "pointer")
  mouseover: (element, selection, projection) ->
    if not Session.get('grits-net-meteor:isUpdating')
      oldPath = Template.gritsMap.currentPath # initialized to null
      if oldPath isnt null
        if element is oldPath.element
          d3.select(element).style("cursor": "pointer")
          return
      d3.select(element).style('stroke', 'black').style("cursor": "pointer")
  click: (element, selection, projection) ->
    if not Session.get('grits-net-meteor:isUpdating')
      oldPath = Template.gritsMap.currentPath # initialized to null
      if oldPath isnt null
        d3.select(oldPath.element).style('stroke', oldPath.color)
      
      # set the gritsPath.element to the d3 element
      @element = element
      
      # temporarily set the path color
      d3.select(element).style('stroke', 'blue')
      # set the currentPath to this gritsPath
      Template.gritsMap.currentPath = this
      # show the pathDetails template
      Template.gritsMap.showPathDetails(this)
}

GritsPathLayer = (map) ->
  GritsLayer.call(this)
  
  if typeof map == 'undefined'
    throw new Error('A layer requires a map to be defined')
    return
  if !map instanceof GritsMap
    throw new Error('A layer requires a valid map instance')
    return
  
  @_name = 'Paths'
  @_map = map
  
  @_layer = L.d3SvgOverlay(_.bind(@_drawCallback, this), {})
  
  @_bindMapEvents()
  return

GritsPathLayer.prototype = Object.create(GritsLayer.prototype)
GritsPathLayer.prototype.constructor = GritsPathLayer

GritsPathLayer::_drawCallback = (selection, projection) ->
  self = this
  arrowhead = d3.select("#arrowhead")
  if typeof arrowhead == 'undefined' or arrowhead[0][0] is null
    svg = d3.select("svg")
    defs = svg.append('defs')
    defs.append('marker').attr(
      'id': 'arrowhead'
      'viewBox': '0 -5 10 10'
      'refX': 5
      'refY': 0
      'opacity': .5
      'markerWidth': 4
      'markerHeight': 4
      'orient': 'auto')
    .append('path')
    .attr('d', 'M0,-5L10,0L0,5')
    .attr('class', 'arrowHead')

  paths = _.sortBy(_.values(self._data, (path) ->
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
      weight = self._getWeight(path)
      return weight / projection.scale
    ).attr("stroke", (path) ->
      if path.clicked
        return 'blue'
      path.color = self._getStyle(path)      
      return path.color
    ).attr("fill", "none")
    .attr("marker-mid":"url(#arrowhead)")
    
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
      weight = self._getWeight(path)
      weight / projection.scale
    ).attr("stroke", (path) ->
      if path.clicked
        return 'blue'
      path.color = self._getStyle(path)      
      return path.color
    ).attr("fill", "none")
    .attr("marker-mid":"url(#arrowhead)")
    .on('mouseover', (path) ->
      path.eventHandlers.mouseover(this, selection, projection)
    ).on('mouseout', (path) ->
      path.eventHandlers.mouseout(this, selection, projection)
    ).on('click', (path)->
      path.eventHandlers.click(this, selection, projection)
    )
  lines.exit()
  return

GritsPathLayer::_getWeight = (path) ->
  path.weight = path.throughput / 250  + 2

GritsPathLayer::_getStyle = (path) ->
  color = '#fef0d9'
  if @_normalizedCI > 0
    x = path.throughput / @_normalizedCI
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

# _bindMapEvents
#
# Binds to the global map.on 'overlyadd' and 'overlayremove' methods
GritsPathLayer::_bindMapEvents = () ->
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
 
GritsPathLayer::convertFlight = (flight, level, origin, destination) ->
  if typeof flight == 'undefined' or flight == null
    return
  if typeof level == 'undefined'
    level = 0
  _id = CryptoJS.MD5(origin._id + destination._id).toString()
  path = @_data[_id]
  if (typeof path == 'undefined' or path == null)
    path = new GritsPath(flight, flight.totalSeats, level, origin, destination)
    path.setEventHandlers(_eventHandlers)
    @_data[path._id] = path
  else
    path.level = level
    path.occurrances += 1
    path.throughput += flight.totalSeats
  if path.throughput > @_normalizedCI
    @_normalizedCI = path.throughput