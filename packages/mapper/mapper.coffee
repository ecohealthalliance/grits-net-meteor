if Meteor.isClient
  if typeof L != 'undefined'

    L.MapPath =  L.Path.extend(
      map: null
      smoothFactor: 1.0
      pointList: null
      pathLine: null
      origin: null
      destination: null
      flight: null
      miles: null
      stops: null
      seats: null
      visible: false
      origin_terminal: null
      destination_terminal: null
      show: () ->
      	@drawPath(@color, @weight, @map)
      hide: () ->
      	@visible = false
      	@map.removeLayer @pathLine
      	#L.MapPaths.removePath(this)
      	#^removes the current MapPath from the set of MapPaths
      initialize: (latlngs) ->
        @pointList = latlngs
        @visible = true
        L.MapPaths.addPath(this)
      initialize2: (origin, destination) ->
        @visible = true
        @origin = origin
        @destination = destination
        L.MapPaths.addPath(this)
      drawPath: (color, weight, map) ->
        @visible = true
        @map = map       
        @color = color
        @weight = weight
        @pathLine = new (L.Polyline)(
          @pointList
          color: color
          weight: weight
          opacity: 0.5
          smoothFactor: 1)
        @pathLine.addTo map
      )

    L.mapPath = (latlngs) ->
      new (L.MapPath)(latlngs)

    L.mapPath = (origin, destination) ->
      new (L.MapPath)(origin,destination)

    L.MapPaths =
      mapPaths : []
      mapPathCount : () ->
        @mapPaths.length
      addPath: (mapPath) ->
        @mapPaths.push(mapPath)
      removePath: (mapPath) ->
        @mapPaths.splice(@mapPaths.indexOf(mapPath), 1)
      showPath: (mapPath) ->
        mapPath.show()
      hidePath: (mapPath) ->
        mapPath.hide()
      hideBetween: (mapNodeA, mapNodeB) ->
        for mapPath in @mapPaths
          mapPath.hide()

    L.MapNode =      
      latlng: null
      airport_code: null
      initialize: (latlng) ->
        @latlng = latlng
        marker = L.marker(latlng).addTo(map);      

    L.MapNodes =
      mapNodes : []
      mapNodeCount : () ->
        @mapNodes.length

    L.mapNode = (latlng) ->
      new (L.MapNode)(latlng)

  else
    console.log 'Leaflet Object [L] is missing.'
