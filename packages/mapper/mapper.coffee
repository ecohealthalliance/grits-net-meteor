if Meteor.isClient
  if typeof L != 'undefined'
    L.Mapper =
      path: null
      pointList: null
      color: null
      weight: null
      opacity: null
      smoothFactor: null      
      drawPath: (pointList, color, weight, map) ->
        firstpolyline = new (L.Polyline)(pointList,
          color: color
          weight: weight
          opacity: 0.5
          smoothFactor: 1)
        firstpolyline.addTo map
  else
    console.log 'Leaflet Object [L] is missing.'
