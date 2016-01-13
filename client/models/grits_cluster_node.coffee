# Creates an instance of a GritsClusterNode
#
# @param [Array] nodes, a list of GritsNodes to create the GritsMetaNode
class GritsClusterNode
  constructor: (nodes, marker) ->
    self = this
    if typeof nodes == 'undefined'
      throw new Error('A GritsClusterNode requires an array of GritsNodes to be defined')
    if !nodes instanceof Array
      throw new Error('A GritsClusterNode requires a valid array of GritsNodes')
    if nodes.length <= 0
      throw new Error('A GritsClusterNode requires an array of GritsNodes')

    self._children = nodes
    self._id = CryptoJS.MD5(JSON.stringify(_.pluck(nodes, '_id'))).toString()

    self.incomingThroughput = 0
    self.outgoingThroughput = 0
    self.level = 0
    self.metadata = {}
    self.eventHandlers = {}

    colorScale =
      10: '#282828'
      20: '#282828'
      30: '#282828'
      40: '#282828'
      50: '#282828'
      60: '#282828'
      70: '#282828'
      80: '#282828'
      90: '#282828'
      100: '#282828'

    if typeof marker != 'undefined' and marker instanceof GritsMarker
      self.marker = marker
    else
      self.marker = new GritsMarker(7, 7, colorScale)

    # find center and add throughput
    latMinMax = [90,-90]
    lngMinMax = [180,-180]
    for node in self._children
      self.incomingThroughput += node.incomingThroughput
      self.outgoingThroughput += node.outgoingThroughput
      if !node instanceof GritsNode
        throw new Error('A GritsClusterNode requires an array of GritsNodes')
      lat = node.latLng[0]
      if typeof lat != 'undefined' || (lat > -90.0 && lat < 90.0)
        if lat < latMinMax[0]
          latMinMax[0] = lat
        if lat > latMinMax[1]
          latMinMax[1] = lat
      lng = node.latLng[1]
      if typeof lng != 'undefined' || (lng < -180.0 && lng > 180.0)
        if lng < lngMinMax[0]
          lngMinMax[0] = lng
        if lng > lngMinMax[1]
          lngMinMax[1] = lng

    self.latLng = [(latMinMax[0] + latMinMax[1]) / 2, (lngMinMax[0] + lngMinMax[1]) / 2]
