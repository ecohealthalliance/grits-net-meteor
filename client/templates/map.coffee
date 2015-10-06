Meteor.startup () ->
  Session.set 'previousDepartureAirports', []
  Session.set 'previousArrivalAirports', []
  Session.set 'previousFlights', []

Meteor.gritsUtil =
  map: null
  baseLayers: null
  queryCrit: []
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
  getQueryCriteria: ->
    jsoo = {}
    for crit in @queryCrit
      jsoo[crit.key] = crit.value
    return jsoo
  removeQueryCriteria:(critId)->
    for crit in @queryCrit
      if crit.critId is critId
        @queryCrit.splice(@queryCrit.indexOf(crit), 1)
  addQueryCriteria: (newQueryCrit) ->
    for crit in @queryCrit
      if crit.critId is newQueryCrit.critId
        @queryCrit.splice(@queryCrit.indexOf(crit), 1)
        @queryCrit.push(newQueryCrit)
        return false #updated
    @queryCrit.push(newQueryCrit)
    return true #added
  showNodeDetails:(node) ->
    $('.node-detail').empty()
    $('.node-detail').hide()
    div = $('.node-detail')[0]
    Blaze.renderWithData Template.nodeDetails, node, div
    $('.node-detail').show()
  showPathDetails:(path) ->
    $('.path-detail').empty()
    $('.path-detail').hide()
    div = $('.path-detail')[0]
    Blaze.renderWithData Template.pathDetails, path, div
    $('.path-detail').show()
  addControl: (position, selector, content) ->
    control = L.control(position: position)
    control.onAdd = @onAddHandler(selector, content)
    control.addTo @map
  addControls: ->
    pathDetails = L.control(position: 'bottomright')
    pathDetails.onAdd = @onAddHandler('info path-detail', '')
    pathDetails.addTo @map
    $('.path-detail').hide()
    nodeDetails = L.control(position: 'bottomright')
    nodeDetails.onAdd = @onAddHandler('info node-detail', '')
    nodeDetails.addTo @map
    $('.node-detail').hide()
  onAddHandler: (selector, html) ->
    ->
      @_div = L.DomUtil.create('div', selector)
      @_div.innerHTML = html
      L.DomEvent.disableClickPropagation @_div
      L.DomEvent.disableScrollPropagation @_div
      @_div

Template.map.events
  'blur input[name="departureSearch"]': (e, template) ->
    tokens = _.map(this.settings.rules, (r) -> r.token)
    template.applyAirportFilter(this.name, tokens)

  'blur input[name="arrivalSearch"]': (e, template) ->
    tokens = _.map(this.settings.rules, (r) -> r.token)
    template.applyAirportFilter(this.name, tokens)

  'autocompleteselect input': (event, template, doc) ->
    tokens = _.map(this.settings.rules, (r) -> r.token)
    template.applyAirportFilter(this.name, tokens)

  'change #stopsInput': ->
    val = parseInt($("#stopsInput").val())
    if _.isUndefined(val) or isNaN(val)
      Meteor.gritsUtil.removeQueryCriteria(1)
    else
      Meteor.gritsUtil.addQueryCriteria({'critId' : 1, 'key' : 'stops', 'value' : val})

  'change #seatsInput': ->
    val = parseInt($("#seatsInput").val())
    if _.isUndefined(val) or isNaN(val)
      Meteor.gritsUtil.removeQueryCriteria(2)
    else
      Meteor.gritsUtil.addQueryCriteria({'critId' : 2, 'key' : 'totalSeats', 'value' : {$gt: val}})

  'click #dowSUN': ->
    if $('#dowSUN').is(':checked')
      Meteor.gritsUtil.addQueryCriteria({'critId' : 3, 'key' : 'day1', 'value' : true})
    else if !$('#dowSUN').is(':checked')
      Meteor.gritsUtil.removeQueryCriteria(3)

  'click #dowMON': ->
    if $('#dowMON').is(':checked')
      Meteor.gritsUtil.addQueryCriteria({'critId' : 4, 'key' : 'day2', 'value' : true})
    else if !$('#dowMON').is(':checked')
      Meteor.gritsUtil.removeQueryCriteria(4)

  'click #dowTUE': ->
    if $('#dowTUE').is(':checked')
      Meteor.gritsUtil.addQueryCriteria({'critId' : 5, 'key' : 'day3', 'value' : true})
    else if !$('#dowTUE').is(':checked')
      Meteor.gritsUtil.removeQueryCriteria(5)

  'click #dowWED': ->
    if $('#dowWED').is(':checked')
      Meteor.gritsUtil.addQueryCriteria({'critId' : 6, 'key' : 'day4', 'value' : true})
    else if !$('#dowWED').is(':checked')
      Meteor.gritsUtil.removeQueryCriteria(6)

  'click #dowTHU': ->
    if $('#dowTHU').is(':checked')
      Meteor.gritsUtil.addQueryCriteria({'critId' : 7, 'key' : 'day5', 'value' : true})
    else if !$('#dowTHU').is(':checked')
      Meteor.gritsUtil.removeQueryCriteria(7)

  'click #dowFRI': ->
    if $('#dowFRI').is(':checked')
      Meteor.gritsUtil.addQueryCriteria({'critId' : 8, 'key' : 'day6', 'value' : true})
    else if !$('#dowFRI').is(':checked')
      Meteor.gritsUtil.removeQueryCriteria(8)

  'click #dowSAT': ->
    if $('#dowSAT').is(':checked')
      Meteor.gritsUtil.addQueryCriteria({'critId' : 9, 'key' : 'day7', 'value' : true})
    else if !$('#dowSAT').is(':checked')
      Meteor.gritsUtil.removeQueryCriteria(9)

  'click #diwCB': ->
    if $('#diwCB').is(':checked')
      Meteor.gritsUtil.addQueryCriteria({'critId' : 10, 'key' : 'weeklyFrequency', 'value' : parseInt($("#weeklyFrequencyInput").val())})
    else if !$('#diwCB').is(':checked')
      Meteor.gritsUtil.removeQueryCriteria(10)

  'click #applyFilter': (e, template) ->
    e.preventDefault()
    e.stopPropagation()
    query = Meteor.gritsUtil.getQueryCriteria()
    template.subscribe 'flightsByQuery', query,
      onError: ->
        console.log 'subscription.flightsByQuery.onError:', this
      onStop: ->
        console.log 'subscription.flightsByQuery.onStop:', this
      onReady: ->
        console.log 'subscription.flightsByQuery.onReady:', this
        console.log 'query: ', query

        flights = Flights.find(query).fetch()
        template.updateExistingAirports(flights) # needed for the Departure,
                                                 # and Arrival searches
        template.updateExistingFlights(query) # alternative to observeChanges

        ###
        Flights.find().observeChanges
          added: (id, fields) ->
            console.log 'add path: ', id
            path = L.MapPaths.addFactor id, fields, Meteor.gritsUtil.map
            Meteor.gritsUtil.styleMapPath(path)
          changed: (id, fields) ->
            console.log 'update path: ', id
            L.MapPaths.updatePath id, fields, Meteor.gritsUtil.map
          removed: (id) ->
            console.log 'remove path: ', id
            pathAndFactor = L.MapPaths.removeFactor id, flight
            if pathAndFactor isnt false
              Meteor.gritsUtil.styleMapPath(pathAndFactor.path)
        ###
@nodeHandler =
  click:(node)->
    Meteor.gritsUtil.showNodeDetails(node)
    $("#departureSearch").val('!'+node.id).blur()
    $("#applyFilter").click()

@pathHandler =
  click:(path)->
    Meteor.gritsUtil.showPathDetails(path)

Template.map.helpers({
  departureAirports: () ->
    return {
      position: "top",
      limit: 10,
      rules: [
        {
          token: '!',
          collection: 'Airports',
          subscription: 'autoCompleteAirports',
          field: '_id',
          template: Template.airportPill,
          filter: {
            $and: [
              {'_id': $in: Session.get('previousDepartureAirports') }
            ]
          }
        },
        {
          token: '@',
          collection: 'Airports',
          subscription: 'autoCompleteAirports',
          field: '_id',
          template: Template.airportPill
        },
      ]
    }
  arrivalAirports: () ->
    return {
      position: "top",
      limit: 10,
      rules: [
        {
          token: '!',
          collection: 'Airports',
          subscription: 'autoCompleteAirports',
          field: '_id',
          template: Template.airportPill,
          filter: {
            $and: [
              {'_id': $in: Session.get('previousArrivalAirports') }
            ]
          }
        },
        {
          token: '@',
          collection: 'Airports',
          subscription: 'autoCompleteAirports',
          field: '_id',
          template: Template.airportPill
        },
      ]
    }
})

Template.map.onCreated () ->
  template = this

  @updateExistingAirports = (flights) ->
    departureAirports = {}
    arrivalAirports = {}
    for flight in flights
      departureAirports[flight.departureAirport._id] = flight.departureAirport._id
      arrivalAirports[flight.arrivalAirport._id] = flight.arrivalAirport._id
    Session.set('previousDepartureAirports', Object.keys(departureAirports))
    Session.set('previousArrivalAirports', Object.keys(arrivalAirports))

  @updateExistingFlights = (query) ->
    # TODO: show loading
    template = this
    previousFlights = Session.get('previousFlights')
    newFlights = Flights.find(query).fetch()

    if previousFlights.length > 0
      newFlightIds = _.pluck(newFlights, '_id')
      previousFlightIds = _.pluck(previousFlights, '_id')
      remove = _.difference(previousFlightIds, newFlightIds);
      add = _.difference(newFlightIds, previousFlightIds);
      update = _.intersection(previousFlightIds, newFlightIds);

      async.each(remove, (id, cb) ->
        flight = _.find(template.previousFlights, (f) -> return f._id == id)
        console.log 'remove flight: ', flight
        pathAndFactor = L.MapPaths.removeFactor id, flight
        if pathAndFactor isnt false
          Meteor.gritsUtil.styleMapPath(pathAndFactor.path)
        cb()
      )

      async.each(add, (id, cb) ->
        flight = _.find(newFlights, (f) -> return f._id == id)
        console.log 'add flight: ', flight
        if !_.isEmpty(flight)
          path = L.MapPaths.addFactor id, flight, Meteor.gritsUtil.map
          Meteor.gritsUtil.styleMapPath(path)
        cb()
      )

      async.each(update, (id, cb) ->
        flight = _.find(newFlights, (f) -> return f._id == id)
        console.log 'update flight: ', flight
        if !_.isEmpty(flight)
          L.MapPaths.updatePath id, flight, Meteor.gritsUtil.map
        cb()
      )

    else
      async.each(newFlights, (flight, cb) ->
        console.log 'add flight: ', flight
        path = L.MapPaths.addFactor flight._id, flight, Meteor.gritsUtil.map
        Meteor.gritsUtil.styleMapPath(path)
        cb()
      )

    template.updateExistingAirports(newFlights)
    Session.set('previousFlights', newFlights)

  @parseAirportCodes = (str, tokens) ->
    codes = {}
    parts = str.split(' ');
    _.each(parts, (part) ->
      if _.isEmpty(part)
        return
      code = part.replace(new RegExp(tokens.join('|'), 'g'), '')
      codes[code] = code;
    )
    return codes

  @applyAirportFilter = (name, tokens) ->
    if name == 'departureSearch'
      val = $('input[name="departureSearch"]').val()
      codes = this.parseAirportCodes(val, tokens)
      if _.isEmpty(codes)
        Meteor.gritsUtil.removeQueryCriteria(10)
      else
        Meteor.gritsUtil.addQueryCriteria({'critId' : 10, 'key' : 'departureAirport._id', 'value' : {$in: Object.keys(codes)}})
    else if name == 'arrivalSearch'
      val = $('input[name="arrivalSearch"]').val()
      codes = this.parseAirportCodes(val, tokens)
      if _.isEmpty(codes)
        Meteor.gritsUtil.removeQueryCriteria(11)
      else
        Meteor.gritsUtil.addQueryCriteria({'critId' : 11, 'key' : 'arrivalAirport._id', 'value' : {$in: Object.keys(codes)}})

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
