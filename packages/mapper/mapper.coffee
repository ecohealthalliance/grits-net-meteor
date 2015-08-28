if Meteor.isClient
  'use strict'
  if typeof L != 'undefined'
    L.MapPath =  L.Path.extend(
      map: null
      smoothFactor: 1.0
      pointList: null
      IDLpointList: null
      pathLine: null
      IDLpathLine: null
      origin: null
      destination: null
      flight: null
      miles: null
      stops: null
      seats: null
      visible: false
      origin_terminal: null
      destination_terminal: null
      archPosition: 0 #defines the arch position for drawing the path on a curve to avoid path overlap
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
      initialize: (origin, destination) ->
        @visible = true
        @origin = origin
        @destination = destination
        @pointList = [origin.latlng, destination.latlng]
        L.MapPaths.addPath(this)
      calculateArch: (archPos)->       
        orgDestDist = Meteor.leafnav.getDistance(@origin.latlng, @destination.latlng, "K")
        #v this works for north south
        pm = @origin.latlng.lng < @destination.latlng.lng or @origin.latlng.lat < @destination.latlng.lat? true : false     
        pts = 100.0
        bng = Math.floor(Meteor.leafnav.getBearing(@origin.latlng, @destination.latlng))
        rbng = Math.ceil(Meteor.leafnav.getBearing(@destination.latlng, @origin.latlng))       
        @archPosition = (archPos.length)
        latArch = 0.0
        lngArch = 0.0
        distBetweenPoints = orgDestDist / pts
        currentPoint = @origin.latlng
        ptCtr = 1
        arcCoords = []
        IDLarcCoords = []        
        arcCoords.push(currentPoint)
        keepDrawing = true
        gain = .10 * @archPosition 
        IDLsplit = false       
        while ptCtr < pts and keepDrawing
          if Meteor.leafnav.getDistance(currentPoint, @destination.latlng) > distBetweenPoints
            if @archPosition isnt 0
              #spread gain across latitude and longitude based on coordinate bearing relation.
              if ptCtr < (pts/2)
                latArch += (gain * ((180-(bng+rbng))/180))
                lngArch += (gain * ((bng+rbng)/180))
              else
                latArch -= (gain * ((180-(bng+rbng))/180))
                lngArch -= (gain * ((bng+rbng)/180))            
            currentPoint = Meteor.leafnav.calculateNewPositionArch(currentPoint, distBetweenPoints, Meteor.leafnav.getBearing(currentPoint, @destination.latlng), latArch*.01, lngArch*.01, pm)
            if currentPoint.lng > 0 and arcCoords[arcCoords.length-1].lng < 0
              IDLsplit = true
            if currentPoint.lng < 0 and arcCoords[arcCoords.length-1].lng > 0
              IDLsplit = true
            if IDLsplit
              IDLarcCoords.push(currentPoint)
            else
              arcCoords.push(currentPoint)
            ptCtr++
          else
            keepDrawing = false
        if IDLsplit                             
          IDLarcCoords.push(@destination.latlng)
        else
          arcCoords.push(@destination.latlng)
        @pointList = arcCoords
        @IDLpointList = IDLarcCoords
      drawPath: (color, weight, map) ->
        @visible = true
        @map = map
        @color = color
        @weight = weight        
        #is there an existing path displayed (visible) between the path nodes?
        archPos = []
        for mapPath in L.MapPaths.mapPaths
          if mapPath isnt this
            if (mapPath.origin.equals @origin) and (mapPath.destination.equals @destination)
              archPos[mapPath.archPosition]=true
            if (mapPath.origin.equals @destination) and (mapPath.destination.equals @origin)
              archPos[mapPath.archPosition]=true
        mapPath.calculateArch(archPos)                
        @pathLine = new (L.Polyline)(
          @pointList
          color: color
          weight: weight
          opacity: 0.5
          smoothFactor: 1)
        if @IDLpointList isnt null
          @IDLpathLine = new (L.Polyline)(
            @IDLpointList
            color: color
            weight: weight
            opacity: 0.5
            smoothFactor: 1)
          @IDLpathLine.addTo map
          @IDLpathLine.bindPopup("<b>path</b>"); 
        @pathLine.addTo map
        @pathLine.bindPopup("<b>path</b>");
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
          if mapPath.origin is mapNodeA and mapPath.destination is mapNodeB
            mapPath.hide()
          if mapPath.origin is mapNodeB and mapPath.destination is mapNodeA
            mapPath.hide()

    L.MapNode = L.Path.extend(
      latlng: null
      airport_code: null
      map: null
      marker: null
      setPopup: (text) ->
        @marker.bindPopup("<b>#{text}</b>");
      initialize: (latlng, map) ->
        @map = map
        @latlng = latlng
        @marker = L.marker(@latlng).addTo(@map);
      equals: (otherNode) ->
        return (otherNode.latlng.lat is this.latlng.lat) and (otherNode.latlng.lng is this.latlng.lng)
      )

    L.MapNodes =
      mapNodes : []
      mapNodeCount : () ->
        @mapNodes.length

    L.mapNode = (latlng, map) ->
      new (L.MapNode)(latlng, map)

  else
    console.log 'Leaflet Object [L] is missing.'
