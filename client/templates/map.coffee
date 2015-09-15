Meteor.startup () ->
  # default query
  Session.set 'query',
    'totalSeats': {$gt: 200}

Meteor.gritsUtil =
  map: null
  baseLayers: null
  imagePath: 'packages/fuatsengul_leaflet/images'
  initWindow: (element, css) ->
    element = element or 'map'
    css = css or {'height': window.innerHeight}
    $(window).resize ->
      $('#'+element).css css
    $(window).resize()
  initLeaflet: (element, view, baseLayers) ->
    L.Icon.Default.imagePath = @imagePath
    # sensible defaults if nothing specified
    element = element or 'grits-map'
    view = view or {}
    view.zoom = view.zoom or 5
    view.latlong = view.latlng or [
      37.8
      -92
    ]
    OpenStreetMap = L.tileLayer('http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      key: '1234'
      layerName: 'OpenStreetMap'
      styleId: 22677)
    baseLayers = baseLayers or [OpenStreetMap]
    @map = L.map(element,
      zoomControl: false
      noWrap: true
      maxZoom: 18
      minZoom: 0
      layers: [ baseLayers[0] ]).setView(view.latlong, view.zoom)
    tempBaseLayers = {}
    for baseLayer in baseLayers
      tempBaseLayers[baseLayer.options.layerName] = baseLayer
    @baseLayers = tempBaseLayers
    if baseLayers.length>1
      L.control.layers(@baseLayers).addTo @map
    @addControls()
  populateMap: (flights) ->
    new L.mapPath(flight, Meteor.gritsUtil.map).addTo(Meteor.gritsUtil.map) for flight in flights
  styleMapPath: (path) ->
    path.hide()
    mid = (100 - Math.floor((path.totalSeats)/100)).toString()
    if mid < 10
      mid = "0"+ mid
    if mid > 99
      mid = "99"
    color = '#99'+ mid + "00"
    weight = path.totalSeats / 250  + 2
    path.setStyle(color, weight)
    path.refresh()
  addControls: ->
    moduleSelector = L.control(position: 'topleft')
    moduleSelector.onAdd = @onAddHandler('info', '<b> Select a Module </b><div id="moduleSelectorDiv"></div>')
    moduleSelector.addTo @map
    $('#moduleSelector').appendTo('#moduleSelectorDiv').show()
    filterSelector = L.control(position: 'bottomleft')
    filterdiv = L.DomUtil.create("div","")
    Blaze.renderWithData(Template.filter, this, filterdiv);
    filterSelector.onAdd = @onAddHandler('info', filterdiv.innerHTML)
    filterSelector.addTo @map
  onAddHandler: (selector, html) ->
    ->
      @_div = L.DomUtil.create('div', selector)
      @_div.innerHTML = html
      L.DomEvent.disableClickPropagation @_div
      L.DomEvent.disableScrollPropagation @_div
      @_div

Meteor.dummyFlight1 = { "_id" : { "$oid" : "55e0a2c72070b47daed4347b"} , "Alliance" : "None" , "Arr Flag" : true , "Arr Term" : "E " , "Arr Time" : 1700.0 , "Block Mins" : 480.0 , "Date" : { "$date" : 1391212800000} , "Dep Term" :  null  , "Dep Time" : 1300.0 , "Dest" : { "City" : "Boston" , "Global Region" : "North America" , "Code" : "BOS" , "Name" : "Logan International" , "loc" : { "type" : "Point" , "coordinates" : [ -115.428235, 70.022733 ]} , "Country" :  null  , "Notes" :  null  , "WAC" : 13 , "State Name" : "Massachusetts" , "State" : "MA" , "Country Name" : "United States" , "key" : "BOS" , "_id" : { "$oid" : "55e0a2862070b47daed4104f"}} , "Dest WAC" : 13 , "Equip" : "752" , "Flight" : 690 , "Miles" :  null  , "Mktg Al" : "VR" , "Op Al" : "VR" , "Op Days" : "...4..." , "Ops/Week" : 1 , "Orig" : { "City" : "Praia" , "Global Region" : "Africa" , "Code" : "RAI" , "Name" : "Praia International" , "loc" : { "type" : "Point" , "coordinates" : [ -115.428235, 15.721201]} , "Country" :  null  , "Notes" :  null  , "WAC" : 507 , "State Name" :  null  , "State" :  null  , "Country Name" : "Cape Verde" , "key" : "RAI" , "_id" : { "$oid" : "55e0a2a62070b47daed42c34"}} , "Orig WAC" : 507 , "Seats" : 210 , "Seats/Week" : 210 , "Stops" : 0 , "key" : "04108e946db07b47ad21875e61c43b8e702b877688962343b8610b65d62555a7"}
Meteor.dummyFlight2 = { "_id" : { "$oid" : "55e0a2c72070b47daed4347b"} , "Alliance" : "None" , "Arr Flag" : true , "Arr Term" : "E " , "Arr Time" : 1700.0 , "Block Mins" : 480.0 , "Date" : { "$date" : 1391212800000} , "Dep Term" :  null  , "Dep Time" : 1300.0 , "Dest" : { "City" : "Boston" , "Global Region" : "North America" , "Code" : "BOS" , "Name" : "Logan International" , "loc" : { "type" : "Point" , "coordinates" : [ 129.576109, 57.749264]} , "Country" :  null  , "Notes" :  null  , "WAC" : 13 , "State Name" : "Massachusetts" , "State" : "MA" , "Country Name" : "United States" , "key" : "BOS" , "_id" : { "$oid" : "55e0a2862070b47daed4104f"}} , "Dest WAC" : 13 , "Equip" : "752" , "Flight" : 690 , "Miles" :  null  , "Mktg Al" : "VR" , "Op Al" : "VR" , "Op Days" : "...4..." , "Ops/Week" : 1 , "Orig" : { "City" : "Praia" , "Global Region" : "Africa" , "Code" : "RAI" , "Name" : "Praia International" , "loc" : { "type" : "Point" , "coordinates" : [ -115.428235, 17.022733]} , "Country" :  null  , "Notes" :  null  , "WAC" : 507 , "State Name" :  null  , "State" :  null  , "Country Name" : "Cape Verde" , "key" : "RAI" , "_id" : { "$oid" : "55e0a2a62070b47daed42c34"}} , "Orig WAC" : 507 , "Seats" : 210 , "Seats/Week" : 210 , "Stops" : 0 , "key" : "04108e946db07b47ad21875e61c43b8e702b877688962343b8610b65d62555a7"}
Meteor.dummyFlight3 = { "_id" : { "$oid" : "55e0a2c72070b47daed4347b"} , "Alliance" : "None" , "Arr Flag" : true , "Arr Term" : "E " , "Arr Time" : 1700.0 , "Block Mins" : 480.0 , "Date" : { "$date" : 1391212800000} , "Dep Term" :  null  , "Dep Time" : 1300.0 , "Dest" : { "City" : "Boston" , "Global Region" : "North America" , "Code" : "BOS" , "Name" : "Logan International" , "loc" : { "type" : "Point" , "coordinates" : [ -115.428235, 17.022733]} , "Country" :  null  , "Notes" :  null  , "WAC" : 13 , "State Name" : "Massachusetts" , "State" : "MA" , "Country Name" : "United States" , "key" : "BOS" , "_id" : { "$oid" : "55e0a2862070b47daed4104f"}} , "Dest WAC" : 13 , "Equip" : "752" , "Flight" : 690 , "Miles" :  null  , "Mktg Al" : "VR" , "Op Al" : "VR" , "Op Days" : "...4..." , "Ops/Week" : 1 , "Orig" : { "City" : "Praia" , "Global Region" : "Africa" , "Code" : "RAI" , "Name" : "Praia International" , "loc" : { "type" : "Point" , "coordinates" : [ 129.576109, 57.749264 ]} , "Country" :  null  , "Notes" :  null  , "WAC" : 507 , "State Name" :  null  , "State" :  null  , "Country Name" : "Cape Verde" , "key" : "RAI" , "_id" : { "$oid" : "55e0a2a62070b47daed42c34"}} , "Orig WAC" : 507 , "Seats" : 210 , "Seats/Week" : 210 , "Stops" : 0 , "key" : "04108e946db07b47ad21875e61c43b8e702b877688962343b8610b65d62555a7"}

Template.map.events
  'click .a': ->
    new L.mapPath(Meteor.dummyFlight1, Meteor.gritsUtil.map).addTo(Meteor.gritsUtil.map)
  'click .b': ->
    L.MapPaths.addFactor 'asdfdewsss', Meteor.dummyFlight2, Meteor.gritsUtil.map
  'click .c': ->
    L.MapPaths.addFactor 'asdfdewsss', Meteor.dummyFlight3, Meteor.gritsUtil.map
  'click .d': ->
    Session.set 'module', 'd'
    new L.marker(new L.LatLng(39.721201, -225.428235)).addTo(Meteor.gritsUtil.map);
  'click .e': ->
    Session.set 'module', 'e'
  'click #stopsCB': ->
    Session.set 'query',
      'stops': parseInt($("#stopsInput").val())
  'click #seatsCB': ->
    Session.set 'query',
      'totalSeats': {$gt: parseInt($("#seatsInput").val())}

Template.map.helpers () ->

Template.map.onCreated () ->
  template = this
  @previousFlights = null
  @autorun () ->
    q = Session.get('query')
    if !_.isUndefined(q) or !_.isEmpty(q)
      template.subscribe 'flightsByQuery', Session.get('query'),
        onError: ->
          console.log 'subscription.flightsByQuery.onError:', this
        onStop: ->
          console.log 'subscription.flightsByQuery.onStop:', this
        onReady: ->
          console.log 'subscription.flightsByQuery.onReady', this

  @updateExistingFlights = ->
    # TODO: show loading
    template = this
    newFlights = Flights.find(Session.get('query')).fetch()
    if template.previousFlights != null
      newFlightIds = _.pluck(newFlights, '_id')
      previousFlightIds = _.pluck(template.previousFlights, '_id')
      remove = _.difference(previousFlightIds, newFlightIds);
      add = _.difference(newFlightIds, previousFlightIds);
      update = _.intersection(previousFlightIds, newFlightIds);

      for id in remove
        flight = _.find(template.previousFlights, (f) -> return f._id == id)
        console.log 'remove flight: ', flight
        pathAndFactor = L.MapPaths.removeFactor id, flight
        if pathAndFactor isnt false
          Meteor.gritsUtil.styleMapPath(pathAndFactor.path)
      for id in add
        flight = _.find(newFlights, (f) -> return f._id == id)
        console.log 'add flight: ', flight
        if !_.isEmpty(flight)
          path = L.MapPaths.addFactor id, flight, Meteor.gritsUtil.map
          Meteor.gritsUtil.styleMapPath(path)
      for id in update
        flight = _.find(newFlights, (f) -> return f._id == id)
        console.log 'update flight: ', flight
        if !_.isEmpty(flight)
          L.MapPaths.updatePath id, flight, Meteor.gritsUtil.map
    else
      newFlights = Flights.find(Session.get('query')).fetch()
      for flight in newFlights
        path = L.MapPaths.addFactor flight._id, flight, Meteor.gritsUtil.map
        Meteor.gritsUtil.styleMapPath(path)
    template.previousFlights = newFlights


Template.map.onRendered () ->
  template = this

  Meteor.gritsUtil.initWindow('grits-map', {'height': window.innerHeight})

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

  Meteor.gritsUtil.initLeaflet('grits-map', {'zoom':2,'latlng':[37.8, -92]}, baseLayers)

  #Meteor.gritsUtil.map.addLayer(L.MapNodes.getLayerGroup())

  #Meteor.gritsUtil.map.addLayer(L.MapPaths.getLayerGroup())

  #L.layerGroup(L.MapPaths.mapPaths).addTo(Meteor.gritsUtil.map)

  #L.layerGroup(L.MapNodes.mapNodes).addTo(Meteor.gritsUtil.map)

  @autorun () ->
    if template.subscriptionsReady()
      # we may update the map now that the subscription has been marked as
      # ready by the server
      template.updateExistingFlights()
