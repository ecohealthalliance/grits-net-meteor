Meteor.startup ->
  Session.set 'previousDepartureAirports', []
  Session.set 'previousArrivalAirports', []
  Session.set 'previousFlights', []
  Session.set 'query', {}
  Session.set 'isUpdating', false

Meteor.gritsUtil =
  normalizedCI: 0
  map: null
  baseLayers: null
  queryCrit: []
  imagePath: 'packages/fuatsengul_leaflet/images'
  initWindow: (element, css) ->
    element = element or 'map'
    css = css or {'height': window.innerHeight}
    $(window).resize ->
      $('#' + element).css css
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
    if baseLayers.length > 1
      L.control.layers(@baseLayers).addTo @map
    @addControls()
  populateMap: (flights) ->
    new L.mapPath(flight, Meteor.gritsUtil.map).addTo(Meteor.gritsUtil.map) for flight in flights
  styleMapPath: (path) ->
    x = path.totalSeats / @normalizedCI
    np = parseFloat(1 - x)
    path.normalizedPercent = np
    if np < .25
      color = '#ffffff'
    else if np < .50
      color = '#0000ff'
    else if np < .75
      color = '#666666'
    else if np <= 1
      color = '#000000'
    weight = path.totalSeats / 250  + 2
    path.setStyle(color, weight)
  getQueryCriteria: ->
    jsoo = {}
    for crit in @queryCrit
      jsoo[crit.key] = crit.value
    return jsoo
  removeQueryCriteria: (critId) ->
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
  showNodeDetails: (node) ->
    $('.node-detail').empty()
    $('.node-detail').hide()
    div = $('.node-detail')[0]
    Blaze.renderWithData Template.nodeDetails, node, div
    $('.node-detail').show()
  showPathDetails: (path) ->
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

  # parseAirportCodes
  #
  # The airport filters are a list of airport codes seperated by spaces.  They
  # may be prefixed with 'tokens.'  These are typically '!' and '@' from the
  # autocompletion feature.
  #
  # @param [String] str, the airport code
  # @param [Array] tokens, the autocompletion tokens
  parseAirportCodes: (str, tokens) ->
    codes = {}
    parts = str.split(' ')
    _.each(parts, (part) ->
      if _.isEmpty(part)
        return
      code = part.replace(new RegExp(tokens.join('|'), 'g'), '')
      codes[code] = code;
    )
    return codes

  # applyAirportFilter
  #
  # The query builder methods (addQueryCriteria, removeQueueCriteria) are
  # called when the UI detects changes to input[name="departureSearch"] and
  # input[name="arrivalSearch"] elements.
  #
  # @param [String] str, the airport code
  # @param [Array] tokens, the autocompletion tokens
  applyAirportFilter: (name, tokens) ->
    if name == 'departureSearch'
      val = $('input[name="departureSearch"]').val()
      codes = this.parseAirportCodes(val, tokens)
      if _.isEmpty(codes)
        Meteor.gritsUtil.removeQueryCriteria(10)
      else
        Meteor.gritsUtil.addQueryCriteria({'critId': 11, 'key': 'departureAirport._id', 'value': {$in: Object.keys(codes)}})
    else if name == 'arrivalSearch'
      val = $('input[name="arrivalSearch"]').val()
      codes = this.parseAirportCodes(val, tokens)
      if _.isEmpty(codes)
        Meteor.gritsUtil.removeQueryCriteria(11)
      else
        Meteor.gritsUtil.addQueryCriteria({'critId': 12, 'key': 'arrivalAirport._id', 'value': {$in: Object.keys(codes)}})

  # updateExistingAirports
  #
  # The collection of flights is iterated to build a set of previous
  # departureAirports and arrivalAirports.  This maintains the application
  # state so that filters against the currently display map may be applied.
  #
  # @param [Collection] newFlights, collection of MongoDb flight records
  updateExistingAirports: (flights) ->
    departureAirports = {}
    arrivalAirports = {}
    for flight in flights
      departureAirports[flight.departureAirport._id] = flight.departureAirport._id
      arrivalAirports[flight.arrivalAirport._id] = flight.arrivalAirport._id
    Session.set('previousDepartureAirports', Object.keys(departureAirports))
    Session.set('previousArrivalAirports', Object.keys(arrivalAirports))

  # updateExistingFlights
  #
  # When Session.set('query') is applied with a new/changed value, Tracker
  # autorun will re-subscribe to the 'flightsByQuery' publication.  When the
  # subscription onReady callback is triggered, onSubscriptionReady method is
  # called.  Subsequently, this method is called to update the map based on
  # its previous state (if any).
  #
  # @param [Collection] newFlights, collection of MongoDb flight records
  updateExistingFlights: (newFlights) ->
    if _.isUndefined(newFlights) or _.isEmpty(newFlights)
      Session.set('isUpdating',false)
      return

    self = this
    previousFlights = Session.get('previousFlights')

    # The following queues will update the map 'asynchronously' based on its
    # previous state.  By pausing execution of each next iteration through
    # nextTick() is it possible to allow the UI to perform work on the current
    # interpreter event loop in order to update the map.
    # https://github.com/caolan/async
    addQueueDrained = new ReactiveVar(false)
    addQueue = async.queue(((flight, callback) ->
      console.log 'add flight: ', flight
      path = L.MapPaths.addFactor flight._id, flight, Meteor.gritsUtil.map
      Meteor.gritsUtil.styleMapPath(path)
      async.nextTick ->
        callback()
    ), 1)
    # callback method for when all items within the queue are processed
    # sets the reactive var to true.
    addQueue.drain = ->
      console.log 'addQueue is done.'
      addQueueDrained.set true

    removeQueueDrained = new ReactiveVar(false)
    removeQueue = async.queue(((flight, callback) ->
      console.log 'remove flight: ', flight
      pathAndFactor = L.MapPaths.removeFactor flight._id, flight
      if pathAndFactor isnt false
        Meteor.gritsUtil.styleMapPath(pathAndFactor.path)
      async.nextTick ->
        callback()
    ), 1)
    # callback method for when all items within the queue are processed
    # sets the reactive var to true.
    removeQueue.drain = ->
      console.log 'removeQueue is done.'
      removeQueueDrained.set true

    updateQueueDrained = new ReactiveVar(false)
    updateQueue = async.queue(((flight, callback) ->
      console.log 'update flight: ', flight
      if !_.isEmpty(flight)
        L.MapPaths.updatePath flight._id, flight, Meteor.gritsUtil.map
      async.nextTick ->
        callback()
    ), 1)
    # callback method for when all items within the queue are processed
    # sets the reactive var to true.
    updateQueue.drain = ->
      console.log 'updateQueue is done.'
      updateQueueDrained.set true

    # hide the ajax-loader and re-enable the applyFilter button
    Tracker.autorun ->
      if addQueueDrained.get() and removeQueueDrained.get() and updateQueueDrained.get()
        Session.set 'isUpdating', false

    if !_.isUndefined(previousFlights) and previousFlights.length > 0
      # these computations will currently give a slight pause to the UI, less
      # than a second with 1k records, before kicking off the async queue.  If
      # it becomes an issue then a similar async strategy may be applied.
      newFlightIds = _.pluck(newFlights, '_id')
      previousFlightIds = _.pluck(previousFlights, '_id')
      removeIds = _.difference(previousFlightIds, newFlightIds)
      addIds = _.difference(newFlightIds, previousFlightIds)
      updateIds = _.intersection(previousFlightIds, newFlightIds)
      toRemove = _.filter(previousFlights, (flight) ->
        return removeIds.indexOf(flight._id) >= 0
      )
      toAdd = _.filter(newFlights, (flight) ->
        return addIds.indexOf(flight._id) >= 0
      )
      toUpdate = _.filter(newFlights, (flight) ->
        return addIds.indexOf(flight._id) >= 0
      )
      # add the collections to the queue and update the map.
      removeQueue.push toRemove
      updateQueue.push toUpdate
      addQueue.push toAdd
    else
      # no previousFlights, only performing add
      removeQueue.push [] # push an empty array so that removeQueueDrained is set true
      updateQueue.push [] # push an empty array so that updateQueueDrained is set true
      addQueue.push newFlights
    #newFlights becomes previousFlights to maintain state
    Session.set('previousFlights', newFlights)

  # onSubscriptionReady
  #
  # This method is triggered with the 'flightsByQuery' subscription onReady
  # callback.  It gets the new flights from the collection and updates the
  # existing nodes (airports) and paths (flights).
  onSubscriptionReady: ->
    query = Session.get 'query'
    flights = Flights.find(query).fetch()
    @updateExistingAirports(flights) # needed for the Departure and Arrival searches
    @updateExistingFlights(flights) # updates the map

Template.map.events
  'blur input[name="departureSearch"]': (e, template) ->
    tokens = _.map(this.settings.rules, (r) -> r.token)
    Meteor.gritsUtil.applyAirportFilter(this.name, tokens)

  'blur input[name="arrivalSearch"]': (e, template) ->
    tokens = _.map(this.settings.rules, (r) -> r.token)
    Meteor.gritsUtil.applyAirportFilter(this.name, tokens)

  'autocompleteselect input': (event, template, doc) ->
    tokens = _.map(this.settings.rules, (r) -> r.token)
    Meteor.gritsUtil.applyAirportFilter(this.name, tokens)

  'change #stopsInput': ->
    val = parseInt($("#stopsInput").val())
    if _.isUndefined(val) or isNaN(val)
      Meteor.gritsUtil.removeQueryCriteria(1)
    else
      Meteor.gritsUtil.addQueryCriteria({'critId': 1, 'key': 'stops', 'value': val})

  'change #seatsInput': ->
    val = parseInt($("#seatsInput").val())
    if _.isUndefined(val) or isNaN(val)
      Meteor.gritsUtil.removeQueryCriteria(2)
    else
      Meteor.gritsUtil.addQueryCriteria({'critId': 2, 'key': 'totalSeats', 'value': {$gt: val}})

  'click #dowSUN': ->
    if $('#dowSUN').is(':checked')
      Meteor.gritsUtil.addQueryCriteria({'critId': 3, 'key': 'day1', 'value': true})
    else if !$('#dowSUN').is(':checked')
      Meteor.gritsUtil.removeQueryCriteria(3)

  'click #dowMON': ->
    if $('#dowMON').is(':checked')
      Meteor.gritsUtil.addQueryCriteria({'critId': 4, 'key': 'day2', 'value': true})
    else if !$('#dowMON').is(':checked')
      Meteor.gritsUtil.removeQueryCriteria(4)

  'click #dowTUE': ->
    if $('#dowTUE').is(':checked')
      Meteor.gritsUtil.addQueryCriteria({'critId': 5, 'key': 'day3', 'value': true})
    else if !$('#dowTUE').is(':checked')
      Meteor.gritsUtil.removeQueryCriteria(5)

  'click #dowWED': ->
    if $('#dowWED').is(':checked')
      Meteor.gritsUtil.addQueryCriteria({'critId': 6, 'key': 'day4', 'value': true})
    else if !$('#dowWED').is(':checked')
      Meteor.gritsUtil.removeQueryCriteria(6)

  'click #dowTHU': ->
    if $('#dowTHU').is(':checked')
      Meteor.gritsUtil.addQueryCriteria({'critId': 7, 'key': 'day5', 'value': true})
    else if !$('#dowTHU').is(':checked')
      Meteor.gritsUtil.removeQueryCriteria(7)

  'click #dowFRI': ->
    if $('#dowFRI').is(':checked')
      Meteor.gritsUtil.addQueryCriteria({'critId': 8, 'key': 'day6', 'value': true})
    else if !$('#dowFRI').is(':checked')
      Meteor.gritsUtil.removeQueryCriteria(8)

  'click #dowSAT': ->
    if $('#dowSAT').is(':checked')
      Meteor.gritsUtil.addQueryCriteria({'critId': 9, 'key': 'day7', 'value': true})
    else if !$('#dowSAT').is(':checked')
      Meteor.gritsUtil.removeQueryCriteria(9)

  'click #diwCB': ->
    if $('#diwCB').is(':checked')
      Meteor.gritsUtil.addQueryCriteria({'critId': 10, 'key': 'weeklyFrequency', 'value': parseInt($("#weeklyFrequencyInput").val())})
    else if !$('#diwCB').is(':checked')
      Meteor.gritsUtil.removeQueryCriteria(10)

  # see applyAirportFilter method above:
  #
  #  departureSearch is critId 11
  #  arrivalSearch is critId 12

  'click #applyFilter': (e, template) ->
    query = Meteor.gritsUtil.getQueryCriteria()
    if _.isUndefined(query) or _.isEmpty(query)
      return
    else
      Session.set 'isUpdating', true
      Session.set 'query', Meteor.gritsUtil.getQueryCriteria()


@nodeHandler =
  click: (node) ->
    Meteor.gritsUtil.showNodeDetails(node)
    $("#departureSearch").val('!' + node.id).blur()
    $("#applyFilter").click()

@pathHandler =
  click: (path) ->
    Meteor.gritsUtil.showPathDetails(path)

Template.map.helpers({
  # departureAirports is the helper for autocompletion module
  departureAirports: ->
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
  # arrivalAirports is the helper for autocompletion module
  arrivalAirports: ->
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

Template.map.onRendered ->
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
  Meteor.gritsUtil.initLeaflet('grits-map', {'zoom': 2,'latlng': [37.8, -92]}, baseLayers)

  # When the template is rendered, setup a Tracker autorun to listen to changes
  # on isUpdating.  This session reactive var enables/disables, shows/hides the
  # applyFilter button and filterLoading indicator.
  this.autorun ->
    isUpdating = Session.get 'isUpdating'
    if isUpdating
      $('#applyFilter').prop('disabled', true)
      $('#filterLoading').show()
    else
      $('#applyFilter').prop('disabled', false)
      $('#filterLoading').hide()
