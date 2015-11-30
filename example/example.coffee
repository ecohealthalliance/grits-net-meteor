if Meteor.isClient
  Meteor.dummyFlights = [
    { "_id": "95586793f1519e7ce3e6649c3c6fa8d77", "carrier": "AA", "flightNumber": 5020, "serviceType": "J", "effectiveDate": { "$date": 1446681600000}, "discontinuedDate": { "$date": 1457740800000}, "day1": true, "day2": true, "day3": true, "day4": true, "day5": true, "day6": true, "day7": true, "departureAirport": { "city": "Charlotte-Douglas", "name": "Charlotte-Douglas International Airport", "loc": { "type": "Point", "coordinates": [ -120.664635, 35.803367]}, "country": null, "notes": null, "stateName": "North Carolina", "WAC": 36, "countryName": "United States", "state": "NC", "globalRegion": "North America", "_id": "CLT"}, "departureCity": "CLT", "departureState": "NC", "departureCountry": "US", "departureTimePub": { "$date": -2208947100000}, "departureUTCVariance": -500, "arrivalAirport": { "city": "Nashville", "name": "Nashville Metro", "loc": { "type": "Point", "coordinates": [ 111.893956, 26.493962 ]}, "country": null, "notes": null, "stateName": "Tennessee", "WAC": 54, "countryName": "United States", "state": "TN", "globalRegion": "North America", "_id": "BNA"}, "arrivalCity": "BNA", "arrivalState": "TN", "arrivalCountry": "US", "arrivalTimePub": { "$date": -2208945660000}, "arrivalUTCVariance": -600, "flightArrivalDayIndicator": "0", "stops": 0, "stopCodes": [ ], "totalSeats": 84},
    { "_id": "95586793f1519e7ce3e6649c3c6fa8d78", "carrier": "AA", "flightNumber": 5021, "serviceType": "J", "effectiveDate": { "$date": 1446681600000}, "discontinuedDate": { "$date": 1457740800000}, "day1": true, "day2": true, "day3": true, "day4": true, "day5": true, "day6": true, "day7": true, "departureAirport": { "city": "Charlotte-Douglas", "name": "Charlotte-Douglas International Airport", "loc": { "type": "Point", "coordinates": [ 116.288488, -23.338438]}, "country": null, "notes": null, "stateName": "North Carolina", "WAC": 36, "countryName": "United States", "state": "NC", "globalRegion": "North America", "_id": "CLT2"}, "departureCity": "CLT", "departureState": "NC", "departureCountry": "US", "departureTimePub": { "$date": -2208947100000}, "departureUTCVariance": -500, "arrivalAirport": { "city": "Nashville", "name": "Nashville Metro", "loc": { "type": "Point", "coordinates": [ 133.163487, 66.330354 ]}, "country": null, "notes": null, "stateName": "Tennessee", "WAC": 54, "countryName": "United States", "state": "TN", "globalRegion": "North America", "_id": "BNA2"}, "arrivalCity": "BNA", "arrivalState": "TN", "arrivalCountry": "US", "arrivalTimePub": { "$date": -2208945660000}, "arrivalUTCVariance": -600, "flightArrivalDayIndicator": "0", "stops": 0, "stopCodes": [ ], "totalSeats": 84},
    { "_id": "95586793f1519e7ce3e6649c3c6fa8d79", "carrier": "AA", "flightNumber": 5022, "serviceType": "J", "effectiveDate": { "$date": 1446681600000}, "discontinuedDate": { "$date": 1457740800000}, "day1": true, "day2": true, "day3": true, "day4": true, "day5": true, "day6": true, "day7": true, "departureAirport": { "city": "Charlotte-Douglas", "name": "Charlotte-Douglas International Airport", "loc": { "type": "Point", "coordinates": [ 116.288488, -23.338438]}, "country": null, "notes": null, "stateName": "North Carolina", "WAC": 36, "countryName": "United States", "state": "NC", "globalRegion": "North America", "_id": "CLT2"}, "departureCity": "CLT", "departureState": "NC", "departureCountry": "US", "departureTimePub": { "$date": -2208947100000}, "departureUTCVariance": -500, "arrivalAirport": { "city": "Nashville", "name": "Nashville Metro", "loc": { "type": "Point", "coordinates": [ 133.163487, 66.330354 ]}, "country": null, "notes": null, "stateName": "Tennessee", "WAC": 54, "countryName": "United States", "state": "TN", "globalRegion": "North America", "_id": "BNA2"}, "arrivalCity": "BNA", "arrivalState": "TN", "arrivalCountry": "US", "arrivalTimePub": { "$date": -2208945660000}, "arrivalUTCVariance": -600, "flightArrivalDayIndicator": "0", "stops": 0, "stopCodes": [ ], "totalSeats": 84}
  ]

  Template.moduleSelector.events
    'click .a': ->
      pathLayer = new GritsPathLayer(Template.gritsMap.getInstance())
      nodeLayer = new GritsNodeLayer(Template.gritsMap.getInstance())
      pathLayer.clear()
      nodeLayer.clear()

      for flight in Meteor.dummyFlights
        nodes = nodeLayer.convertFlight(flight)
        pathLayer.convertFlight(flight, 1, nodes[0], nodes[1])

      pathLayer.draw()
      nodeLayer.draw()
      return
    'click .b': ->
      return
    'click .c': ->
      return
    'click .d': ->
      return
    'click .e': ->
      return

  Template.gritsMap.onRendered ->
    
    OpenStreetMap = L.tileLayer('http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      key: '1234'
      layerName: 'OpenStreetMap'
      styleId: 22677)
    MapQuestOpen_OSM = L.tileLayer('http://otile{s}.mqcdn.com/tiles/1.0.0/{type}/{z}/{x}/{y}.{ext}',
      type: 'map'
      layerName: 'MapQuestOpen_OSM'
      ext: 'jpg'
      subdomains: '1234')
    Esri_WorldImagery = L.tileLayer('http://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      layerName: 'Esri_WorldImagery')
    
    baseLayers = [OpenStreetMap, Esri_WorldImagery, MapQuestOpen_OSM]    
    view = {'zoom': 2,'latlng': [30,-20]}
    
    map = new GritsMap('grits-map', view, baseLayers)
    map.init()
    map.addLayer(new GritsHeatmapLayer(map))
    map.addLayer(new GritsPathLayer(map))
    map.addLayer(new GritsNodeLayer(map))
    
    # Add the default controls to the map.
    Template.gritsMap.addDefaultControls(map)
    
    # Add custom control
    map.addControl('topleft', 'info', '<b> Select a Module </b><div id="moduleSelectorDiv"></div>')
    Blaze.render(Template.moduleSelector, $('#moduleSelectorDiv')[0])
    
    Template.gritsMap.setInstance(map)
    return
