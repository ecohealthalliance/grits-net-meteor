_eventHandlers = {
  mouseout: (element, selection, projection) ->
    if not Session.get('grits-net-meteor:isUpdating')
      oldPath = Template.gritsMap.getCurrentPath() # initialized to null
      if oldPath isnt null
        if element is oldPath
          d3.select(element).style("cursor": "pointer")
          return
      d3.select(element).style('stroke', @color).style("cursor": "pointer")
  mouseover: (element, selection, projection) ->
    if not Session.get('grits-net-meteor:isUpdating')
      oldPath = Template.gritsMap.getCurrentPath() # initialized to null
      if oldPath isnt null
        if element is oldPath
          d3.select(element).style("cursor": "pointer")
          return
      d3.select(element).style('stroke', 'black').style("cursor": "pointer")
  click: (element, selection, projection) ->
    if not Session.get('grits-net-meteor:isUpdating')
      oldPath = Template.gritsMap.getCurrentPath() # initialized to null
      @element = element
      if oldPath is element
        d3.select(oldPath.__data__.element).style('stroke', oldPath.__data__.color)
        oldPath.__data__.clicked = false
        $("#" + oldPath.__data__._id + "_pathId").removeClass('activeRow')
        Template.gritsMap.setCurrentPath(null)
        Template.gritsMap.hidePathDetails()
        return
      if oldPath isnt null
        d3.select(oldPath.__data__.element).style('stroke', oldPath.__data__.color)
        $("#" + oldPath.__data__._id + "_pathId").removeClass('activeRow')
        oldPath.__data__.clicked = false

      # set the gritsPath.element to the d3 element

      # temporarily set the path color
      $("#" + element.__data__._id + "_pathId").addClass('activeRow')
      d3.select(element).style('stroke', 'blue')
      # set the currentPath to this gritsPath
      Template.gritsMap.setCurrentPath(element)
      Template.gritsMap.setCurrentRow($("#" + element.__data__._id + "_pathId")[0])
      # show the pathDetails template
      Template.gritsMap.showPathDetails(this)
}
# Creates an instance of a GritsNodeLayer, extends  GritsLayer
#
# @param [Object] map, an instance of GritsMap
class GritsPathLayer extends GritsLayer
  constructor: (map) ->
    GritsLayer.call(this) # invoke super constructor
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

  # The D3 callback that renders the svg elements on the map
  #
  # @see https://github.com/mbostock/d3/wiki/API-Reference
  # @see https://github.com/mbostock/d3/wiki/Selections
  # @param [Object] selection, teh array of elements pulled from the current
  #   document, also includes helper methods for filtering similar to jQuery
  # @param [Object] projection, the current scale
  _drawCallback: (selection, projection) ->
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
      .attr("id", (path) ->
        return path._id
      ).attr("marker-mid": "url(#arrowhead)")
      .on('mouseover', (path) ->
        path.eventHandlers.mouseover(this, selection, projection)
      ).on('mouseout', (path) ->
        path.eventHandlers.mouseout(this, selection, projection)
      ).on('click', (path) ->
        path.eventHandlers.click(this, selection, projection)
      )

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
      .attr("id", (path) ->
        return path._id
      ).attr("marker-mid": "url(#arrowhead)")
      .on('mouseover', (path) ->
        path.eventHandlers.mouseover(this, selection, projection)
      ).on('mouseout', (path) ->
        path.eventHandlers.mouseout(this, selection, projection)
      ).on('click', (path) ->
        path.eventHandlers.click(this, selection, projection)
      )
    lines.exit()
    return

  # returns the path's weight based on throughput
  #
  # @return [Number] weight
  _getWeight: (path) ->
    path.weight = path.throughput / 250  + 2

  # returns normalized hex color code for a path
  #
  # @return [String] normalizedColor, a hex string
  _getStyle: (path) ->
    path.color = '#fef0d9'
    if @_normalizedCI > 0
      x = path.throughput / @_normalizedCI
      np = parseFloat(1 - (1 - x))
      path.normalizedPercent = np
      if np < .20
        path.color = '#fef0d9'
      else if np < .40
        path.color = '#fdcc8a'
      else if np < .60
        path.color = '#fc8d59'
      else if np < .80
        path.color = '#e34a33'
      else if np <= 1
        path.color = '#b30000'
    return path.color

  # converts domain specific flight data into generic GritsNode nodes
  #
  # @param [Object] flight, an Astronomy class 'Flight' represending a single
  #   record from a MongoDB collection
  convertFlight: (flight, level, origin, destination) ->
    if typeof flight == 'undefined' or flight == null
      return
    if typeof level == 'undefined'
      level = 0
    _id = CryptoJS.MD5(origin._id + destination._id).toString()
    path = @_data[_id]
    if (typeof path == 'undefined' or path == null)
      try
        path = new GritsPath(flight, flight.totalSeats, level, origin, destination)
        path.setEventHandlers(_eventHandlers)
        @_data[path._id] = path
      catch e
        console.error(e.message)
        return
    else
      path.level = level
      path.occurrances += 1
      path.throughput += flight.totalSeats
    if path.throughput > @_normalizedCI
      @_normalizedCI = path.throughput
    return

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
