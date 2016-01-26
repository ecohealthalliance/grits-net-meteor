_nextNum = 1
_metaNodes = {}
# containers to add shapes from the metanode(s)
_layerGroup = {}
_layers = {}

# Creates an instance of a GritsMetaNode
#
# @param [Array] nodes, a list of GritsNodes to create the GritsMetaNode
class GritsMetaNode
  constructor: (nodes, map, options) ->
    self = this

    if typeof nodes == 'undefined'
      throw new Error('A GritsMetaNode requires an array of GritsNodes to be defined')
    if !nodes instanceof Array
      throw new Error('A GritsMetaNode requires a valid array of GritsNodes')
    self._children = nodes

    if typeof map == 'undefined'
      throw new Error('A GritsMetaNode requires a GritsMap to be defined')
    if !map instanceof GritsMap
      throw new Error('A GritsMetaNode requires a valid GritsMap instance')
    self._map = map

    if typeof options == 'undefined'
      self._options =
        stroke: true
        weight: 2
        opacity: 0.35
        color: '#333'
        fill: true
        fillColor: null
        fillOpacity: 0.15
        clickable: true

    self.bounds = self.findBounds()
    if self.bounds != null
      self._shape = new L.Rectangle(self.bounds, self._options)
      self._shape.addEventListener('click', self._onClickHandler, self)
    else
      self._shape = null

    # add metanode to the layer
    if self._shape != null
      _layers[self._id] = self._shape

    self._id = GritsMetaNode.PREFIX + _nextNum
    _nextNum += 1

    self.incomingThroughput = 0
    self.outgoingThroughput = 0
    self.level = 0

    self.eventHandlers = {}
    self.latLng = self.findCenterPoint()

    _metaNodes[self._id] = self

  _onClickHandler: () ->
    self = this
    console.log('self: ', self)

  findCenterPoint: () ->
    self = this
    # find center and add throughput
    latMinMax = [90,-90]
    lngMinMax = [180,-180]
    for node in self._children
      if !node instanceof GritsNode
        throw new Error('A GritsMetaNode requires an array of GritsNodes')
      lat = node.latLng[0]
      if !(typeof lat == 'undefined' || lat == null || isNaN(parseFloat(lat)) || (lat < -90.0 || lat > 90.0))
        if lat < latMinMax[0]
          latMinMax[0] = lat
        if lat > latMinMax[1]
          latMinMax[1] = lat
      lng = node.latLng[1]
      if !(typeof lng == 'undefined' || lng == null || isNaN(parseFloat(lng)) || (lng < -180.0 || lng > 180.0))
        if lng < lngMinMax[0]
          lngMinMax[0] = lng
        if lng > lngMinMax[1]
          lngMinMax[1] = lng
    if (latMinMax == [90,-90] && lngMinMax == [180,-180])
      return null
    else
      return [(latMinMax[0] + latMinMax[1]) / 2, (lngMinMax[0] + lngMinMax[1]) / 2]
  findBounds: () ->
    self = this
    topLeft = [null,null]
    bottomRight = [null,null]
    for node in self._children
      if !node instanceof GritsNode
        throw new Error('A GritsMetaNode requires an array of GritsNodes')
      lat = node.latLng[0]
      if !(typeof lat == 'undefined' || lat == null || isNaN(parseFloat(lat)) || (lat < -90.0 || lat > 90.0))
        if topLeft[0] == null
          topLeft[0] = lat
        else
          if lat > topLeft[0]
            topLeft[0] = lat
        if bottomRight[0] == null
          bottomRight[0] = lat
        else
          if lat < bottomRight[0]
            bottomRight[0] = lat
      lng = node.latLng[1]
      if !(typeof lng == 'undefined' || lng == null || isNaN(parseFloat(lng)) || (lng < -180.0 || lng > 180.0))
        if topLeft[1] == null
          topLeft[1] = lng
        else
          if lng < topLeft[1]
            topLeft[1] = lng
        if bottomRight[1] == null
          bottomRight[1] = lng
        else
          if lng > bottomRight[1]
            bottomRight[1] = lng
    if (_.indexOf(topLeft, null) >= 0 || _.indexOf(bottomRight, null) >= 0)
      return null
    else
      return new L.LatLngBounds(topLeft, bottomRight)

GritsMetaNode.PREFIX = 'META:'
GritsMetaNode.find = (id) ->
  if _metaNodes.hasOwnProperty(id)
    return _metaNodes[id]
  else
    return null
GritsMetaNode.all = () ->
  return _.values(_metaNodes)
GritsMetaNode.addLayerGroupToMap = (map) ->
  _layerGroup = L.layerGroup(_.values(_layers))
  map.addLayer(_layerGroup)
  return
GritsMetaNode.reset = (map) ->
  GritsMetaNode.removeLayerGroupFromMap(map)
  # cleanup event listeners
  Object.keys(_metaNodes).forEach((key) ->
    metaNode = _metaNodes[key]
    metaNode._shape.removeEventListener('click')
  )
  _metaNodes = {}
  _layers = {}
  _layerGroup = {}
  return
GritsMetaNode.removeLayerGroupFromMap = (map) ->
  if Object.keys(_layerGroup).length > 0
    map.removeLayer(_layerGroup)
  return
