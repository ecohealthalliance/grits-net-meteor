Meteor.startup ->
  Session.set 'previousDepartureAirports', []
  Session.set 'previousArrivalAirports', []
  #Session.set 'previousFlights', []
  Session.set 'query', null
  Session.set 'isUpdating', false
  Session.set 'loadedRecords', 0
  Session.set 'totalRecords', 0

Meteor.gritsUtil =
  debug: true
  autoCompleteTokens: ['!', '@']
  lastId: null # stores the lastId from the collection, used in limit/offset
  getLastFlightId: () ->
    @lastId
  setLastFlightId: () ->
    lastFlight = null
    if @localFlights.find().count() > 0
      options =
        sort:
          _id: -1
      lastFlight = @localFlights.find({}, options).fetch()[0];
    if lastFlight
      @lastId = lastFlight._id
  localFlights: new Mongo.Collection(null)
  loadedRecords: null
  addQueueDrained: new ReactiveVar(false)
  updateQueueDrained: new ReactiveVar(false)
  removeQueueDrained: new ReactiveVar(false)
  normalizedCI: 0
  map: null
  baseLayers: null
  # @poroperty [Array<JSON>] containing current query criteria
  queryCrit: []
  imagePath: 'packages/fuatsengul_leaflet/images'
  # Initialize the window the map will be rendered
  #
  # @param [String] element - id of the containing div
  # @param [JSON] css - CSS to be applied to the containing div
  initWindow: (element, css) ->
    element = element or 'map'
    css = css or {'height': window.innerHeight}
    $(window).resize ->
      $('#' + element).css css
    $(window).resize()
  # Initialize leaflet map
  #
  # @param [String] element - id of the containing div
  # @param [JSON] view - map view options
  # @param [Array<L.tileLayer>] baseLayers - map layers
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
  # Style the MapPath polyline (set the color and weight)
  #
  # @param [L.MapPath] path - L.MapPath instance to be styled
  styleMapPath: (path) ->
    x = path.totalSeats / Meteor.gritsUtil.normalizedCI
    np = parseFloat(1-(1 - x))
    path.normalizedPercent = np
    if np < .20
      color = '#fef0d9'
    else if np < .40
      color = '#fdcc8a'
    else if np < .60
      color = '#fc8d59'
    else if np < .80
      color = '#e34a33'
    else if np <= 1
      color = '#b30000'
    weight = path.totalSeats / 250  + 2
    path.setStyle(color, weight)
  # Get the JSON formatted Meteor.gritsUtil.queryCrit
  #
  # @return [JSON] JSON formatted Meteor.gritsUtil.queryCrit
  getQueryCriteria: ->
    jsoo = {}
    for crit in @queryCrit
      jsoo[crit.key] = crit.value
    return jsoo
  # Remove query criteria from Meteor.gritsUtil.queryCrit
  #
  # @param [int] critId - Id of queryCrit to be removed
  # @return [JSON] JSON formatted Meteor.gritsUtil.queryCrit
  removeQueryCriteria: (critId) ->
    for crit in @queryCrit
      if _.isEmpty(crit)
        return
      else
        if crit.critId is critId
          @queryCrit.splice(@queryCrit.indexOf(crit), 1)
  # Add query criteria to Meteor.gritsUtil.queryCrit
  #
  # @param [JSON] newQueryCrit - queryCrit to be added to Meteor.gritsUtil.queryCrit
  # @return [JSON] JSON formatted Meteor.gritsUtil.queryCrit
  addQueryCriteria: (newQueryCrit) ->
    for crit in @queryCrit
      if crit.critId is newQueryCrit.critId
        @queryCrit.splice(@queryCrit.indexOf(crit), 1)
        @queryCrit.push(newQueryCrit)
        return false #updated
    @queryCrit.push(newQueryCrit)
    return true #added
  # Clears the current node details and renders the current node's details
  #
  # @param [L.MapNode] node - node for which details will be displayed
  showNodeDetails: (node) ->
    $('.node-detail').empty()
    $('.node-detail').hide()
    div = $('.node-detail')[0]
    Blaze.renderWithData Template.nodeDetails, node, div
    $('.node-detail').show()
  # Clears the current path details and renders the current path's details
  #
  # @param [L.MapPath] path - path for which details will be displayed
  showPathDetails: (path) ->
    $('.path-detail').empty()
    $('.path-detail').hide()
    div = $('.path-detail')[0]
    Blaze.renderWithData Template.pathDetails, path, div
    $('.path-detail').show()
  # addControl
  #
  # Add a single control to the map.
  addControl: (position, selector, content) ->
    control = L.control(position: position)
    control.onAdd = @onAddHandler(selector, content)
    control.addTo @map
  # Adds control overlays to the map
  # -Module Selector
  # -Path details
  # -Node details
  addControls: ->
    pathDetails = L.control(position: 'bottomright')
    pathDetails.onAdd = @onAddHandler('info path-detail', '')
    pathDetails.addTo @map
    $('.path-detail').hide()
    nodeDetails = L.control(position: 'bottomright')
    nodeDetails.onAdd = @onAddHandler('info node-detail', '')
    nodeDetails.addTo @map
    $('.node-detail').hide()
  # @note This method is used for initializing dialog boxes created via addControls
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
  parseAirportCodes: (str) ->
    self = this
    codes = {}
    parts = str.split(' ')
    _.each(parts, (part) ->
      if _.isEmpty(part)
        return
      code = part.replace(new RegExp(self.autoCompleteTokens.join('|'), 'g'), '')
      codes[code] = code;
    )
    return codes
  # applyFilters
  #
  # Iterate over the filters object then invoke its values.
  applyFilters: ->
    for filterName, filterMethod of @filters
      filterMethod()
  filters:
    # seatsFilter
    #
    # apply a filter on number of seats if it is not undefined or NaN
    seatsFilter: () ->
      value = {}
      val = parseInt($("#seatsInput").val())
      op = $('#seats-operand').val();
      if _.isUndefined(op)
        return
      if _.isUndefined(val) or isNaN(val)
        Meteor.gritsUtil.removeQueryCriteria(2)
      else
        if op == '$eq'
          value = val
        else
          value[op] = val
        Meteor.gritsUtil.addQueryCriteria({'critId': 2, 'key': 'totalSeats', 'value': value})
    # applyStopsFilter
    #
    # apply a filter on number of stops if it is not undefined or NaN
    stopsFilter: () ->
      value = {}
      val = parseInt($("#stopsInput").val())
      op = $('#stops-operand').val();
      if _.isUndefined(op)
        return
      if _.isUndefined(val) or isNaN(val)
        Meteor.gritsUtil.removeQueryCriteria(1)
      else
        if op == '$eq'
          value = val
        else
          value[op] = val
        Meteor.gritsUtil.addQueryCriteria({'critId': 1, 'key': 'stops', 'value': value})
    # departureSearchFilter
    #
    # apply a filter on the parsed airport codes from the departureSearch input
    # @param [String] str, the airport code
    departureSearchFilter: () ->
      val = $('input[name="departureSearch"]').val()
      codes = Meteor.gritsUtil.parseAirportCodes(val)
      if _.isEmpty(codes)
        Meteor.gritsUtil.removeQueryCriteria(11)
      else
        Meteor.gritsUtil.addQueryCriteria({'critId': 11, 'key': 'departureAirport._id', 'value': {$in: Object.keys(codes)}})
    # arrivalSearchFilter
    #
    # apply a filter on the parsed airport codes from the arrivalSearch input
    # @param [String] str, the airport code
    arrivalSearchFilter: () ->
      val = $('input[name="arrivalSearch"]').val()
      codes = Meteor.gritsUtil.parseAirportCodes(val)
      if _.isEmpty(codes)
        Meteor.gritsUtil.removeQueryCriteria(12)
      else
        Meteor.gritsUtil.addQueryCriteria({'critId': 12, 'key': 'arrivalAirport._id', 'value': {$in: Object.keys(codes)}})
    daysOfWeekFilter: () ->
      if $('#dowSUN').is(':checked')
        Meteor.gritsUtil.addQueryCriteria({'critId': 3, 'key': 'day1', 'value': true})
      else if !$('#dowSUN').is(':checked')
        Meteor.gritsUtil.removeQueryCriteria(3)

      if $('#dowMON').is(':checked')
        Meteor.gritsUtil.addQueryCriteria({'critId': 4, 'key': 'day2', 'value': true})
      else if !$('#dowMON').is(':checked')
        Meteor.gritsUtil.removeQueryCriteria(4)

      if $('#dowTUE').is(':checked')
        Meteor.gritsUtil.addQueryCriteria({'critId': 5, 'key': 'day3', 'value': true})
      else if !$('#dowTUE').is(':checked')
        Meteor.gritsUtil.removeQueryCriteria(5)

      if $('#dowWED').is(':checked')
        Meteor.gritsUtil.addQueryCriteria({'critId': 6, 'key': 'day4', 'value': true})
      else if !$('#dowWED').is(':checked')
        Meteor.gritsUtil.removeQueryCriteria(6)

      if $('#dowTHU').is(':checked')
        Meteor.gritsUtil.addQueryCriteria({'critId': 7, 'key': 'day5', 'value': true})
      else if !$('#dowTHU').is(':checked')
        Meteor.gritsUtil.removeQueryCriteria(7)

      if $('#dowFRI').is(':checked')
        Meteor.gritsUtil.addQueryCriteria({'critId': 8, 'key': 'day6', 'value': true})
      else if !$('#dowFRI').is(':checked')
        Meteor.gritsUtil.removeQueryCriteria(8)

      if $('#dowSAT').is(':checked')
        Meteor.gritsUtil.addQueryCriteria({'critId': 9, 'key': 'day7', 'value': true})
      else if !$('#dowSAT').is(':checked')
        Meteor.gritsUtil.removeQueryCriteria(9)
    weeklyFrequencyFilter: () ->
      value = {}
      val = parseInt($("#weeklyFrequencyInput").val())
      op = $('#weekly-frequency-operand').val();
      if _.isUndefined(op)
        return
      if _.isUndefined(val) or isNaN(val)
        Meteor.gritsUtil.removeQueryCriteria(10)
      else
        if op == '$eq'
          value = val
        else
          value[op] = val
        Meteor.gritsUtil.addQueryCriteria({'critId': 10, 'key': 'weeklyFrequency', 'value': value})

  # clearLocalFlights
  #
  # remove all the flight paths from the collection
  clearLocalFlights: () ->
    @localFlights.remove({})

  appendExistingAirports: (flights) ->
    departureAirports = Session.get('previousDepartureAirports')
    arrivalAirports = Session.get('previousArrivalAirports')
    for flight in flights
      departureAirports[flight.departureAirport._id] = flight.departureAirport._id
      arrivalAirports[flight.arrivalAirport._id] = flight.arrivalAirport._id
    Session.set('previousDepartureAirports', Object.keys(departureAirports))
    Session.set('previousArrivalAirports', Object.keys(arrivalAirports))

  appendExistingFlights: (flights) ->
    self = this
    appendQueue = async.queue(((flight, callback) ->
      if Meteor.gritsUtil.debug
        console.log 'append flight: ', flight
      self.localFlights.upsert(flight._id, flight)
      path = L.MapPaths.addFactor flight._id, flight, self.map
      Meteor.gritsUtil.styleMapPath(path)
      async.nextTick ->
        callback()
    ), 1)
    # callback method for when all items within the queue are processed
    # sets the reactive var isUpdating to false.
    appendQueue.drain = ->
      if Meteor.gritsUtil.debug
        console.log 'appendQueue is done.'
      # update Session
      Session.set 'isUpdating', false
      # set lastId
      Meteor.gritsUtil.setLastFlightId()
    appendQueue.push flights

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
    self = this
    self.isUpdateExistingFlights = true
    previousFlights = self.localFlights.find({}).fetch();
    #self.clearLocalFlights()
    if Meteor.gritsUtil.debug
      console.log 'previousFlights: ', previousFlights

    # The following queues will update the map 'asynchronously' based on its
    # previous state.  By pausing execution of each next iteration through
    # nextTick() is it possible to allow the UI to perform work on the current
    # interpreter event loop in order to update the map.
    # https://github.com/caolan/async
    self.addQueueDrained.set false
    addQueue = async.queue(((flight, callback) ->
      if Meteor.gritsUtil.debug
        console.log 'add flight: ', flight
      self.localFlights.upsert(flight._id, flight)
      path = L.MapPaths.addFactor flight._id, flight, self.map

      async.nextTick ->
        callback()
    ), 1)
    # callback method for when all items within the queue are processed
    # sets the reactive var to true.
    addQueue.drain = ->
      if Meteor.gritsUtil.debug
        console.log 'addQueue is done.'
      self.addQueueDrained.set true

    self.removeQueueDrained.set false
    removeQueue = async.queue(((flight, callback) ->
      if Meteor.gritsUtil.debug
        console.log 'remove flight: ', flight
      self.localFlights.remove flight._id
      pathAndFactor = L.MapPaths.removeFactor flight._id, flight
      async.nextTick ->
        callback()
    ), 1)

    # callback method for when all items within the queue are processed
    # sets the reactive var to true.
    removeQueue.drain = ->
      if Meteor.gritsUtil.debug
        console.log 'removeQueue is done.'
      self.removeQueueDrained.set true
    styleMapPaths = ->
      @normalizedCI = 0;
      i = 0
      newNCI = 0
      while i < L.MapPaths.mapPaths.length
        if L.MapPaths.mapPaths[i].totalSeats > newNCI
          newNCI = L.MapPaths.mapPaths[i].totalSeats
        i++
      Meteor.gritsUtil.normalizedCI = newNCI
      i = 0
      while i < L.MapPaths.mapPaths.length
        if L.MapPaths.mapPaths[i].flights >= 1
          Meteor.gritsUtil.styleMapPath(L.MapPaths.mapPaths[i])
        i++

    updateQueueDrained = new ReactiveVar(false)

    updateQueue = async.queue(((flight, callback) ->
      if Meteor.gritsUtil.debug
        console.log 'update flight: ', flight
      if !_.isEmpty(flight)
        try
          L.MapPaths.updateFactor flight._id, flight, self.map
          self.localFlights.upsert(flight._id, flight)
        catch
      async.nextTick ->
        callback()
    ), 1)
    # callback method for when all items within the queue are processed
    # sets the reactive var to true.
    updateQueue.drain = ->
      if Meteor.gritsUtil.debug
        console.log 'updateQueue is done.'
      self.updateQueueDrained.set true

    # hide the ajax-loader and re-enable the applyFilter button
    Tracker.autorun ->
      if self.isUpdateExistingFlights
        if self.addQueueDrained.get() and self.removeQueueDrained.get() and self.updateQueueDrained.get()
          self.isUpdateExistingFlights = false
          Session.set 'isUpdating', false
          styleMapPaths()
          # set lastFlightId
          self.setLastFlightId()

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

  # onSubscriptionReady
  #
  # This method is triggered with the 'flightsByQuery' subscription onReady
  # callback.  It gets the new flights from the collection and updates the
  # existing nodes (airports) and paths (flights).
  onSubscriptionReady: ->
    query = Session.get 'query'
    flights = Flights.find(query).fetch()
    if Meteor.gritsUtil.debug
      console.log 'flights: ', flights
    @updateExistingFlights(flights) # updates the map from the previous state
    @updateExistingAirports(flights) # needed for the Departure and Arrival searches

  onMoreSubscriptionsReady: ->
    query = Session.get 'query'
    flights = Flights.find(query).fetch()
    if Meteor.gritsUtil.debug
      console.log 'flights: ', flights
    @appendExistingAirports(flights) # appends to the Departure and Arrival searches
    @appendExistingFlights(flights) # appends the map
