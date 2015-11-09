Meteor.startup ->
  Session.set 'previousDepartureAirports', []
  Session.set 'previousArrivalAirports', []
  #Session.set 'previousFlights', []
  Session.set 'query', null
  Session.set 'isUpdating', false
  Session.set 'loadedRecords', 0
  Session.set 'totalRecords', 0

Meteor.gritsUtil =
  pathLevelIds: []
  debug: true
  autoCompleteTokens: ['!', '@']
  lastId: null # stores the lastId from the collection, used in limit/offset
  origin: null
  nodeDetail: null # stores ref to the Blaze Template that shows a nodes detail
  nodeLayer: null # stores ref to the d3 layer containing the nodes
  pathLayer: null # stores ref to the d3 layer containing the paths
  currentLevel: 1 # current level of connectedness depth
  currentPath: null #currently selected path svg element

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
  overlays: {}
  overlayControl: null
  normalizedCI: 0
  map: null
  lineFunction: null
  lineData: null
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
    view.latlng = view.latlng or [
      0,
      0
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
      layers: [ baseLayers[0] ])
    console.log('view: ', view)
    @map.setView(view.latlng, view.zoom)
    tempBaseLayers = {}
    for baseLayer in baseLayers
      tempBaseLayers[baseLayer.options.layerName] = baseLayer
    @baseLayers = tempBaseLayers
    @pathLayer = new GritsPathLayer()
    # create an instance of GritsHeatmap and keep reference within
    # gritsUtil.heatmap
    @heatmap = new GritsHeatmap()
    @nodeLayer = new GritsNodeLayer()

    # draw overlay controls. Note: the constructor of GritsHeatmap calls the
    # method @addOverlayControl to add itself.
    @drawOverlayControls()
    @addControls()

  # Draws the overlay controls within the control box in the upper-right
  # corner of the map.  It uses @overlayControl to place the reference of
  # the overlay controls.
  drawOverlayControls: () ->
    if @overlayControl == null
      @overlayControl = L.control.layers(@baseLayers, @overlays).addTo @map
    else
      @overlayControl.removeFrom(@map)
      @overlayControl = L.control.layers(@baseLayers, @overlays).addTo @map
  # addOverlayControl, adds a new overlay control to the map
  addOverlayControl: (layerName, layerGroup) ->
    @overlays[layerName] = layerGroup
    @drawOverlayControls()
  # removeOverlayControl, removes overlay control from the map
  removeOverlayControl: (layerName) ->
    if @overlays.hasOwnProperty layerName
      delete @overlays[layerName]
      @drawOverlayControls()
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
  # @param [GritsNode] node - node for which details will be displayed
  showNodeDetails: (node) ->
    $('.node-detail').empty()
    $('.node-detail').hide()
    div = $('.node-detail')[0]
    @nodeDetail = Blaze.renderWithData Template.nodeDetails, node, div
    $('.node-detail').show()
    $('.node-detail-close').off().on('click', (e) ->
      $('.node-detail').hide()
    )

  updateNodeDetails: () ->
    if typeof @nodeDetail == 'undefined' or @nodeDetail == null
      return
    previousNode = @nodeDetail.dataVar.get()
    newNode = @nodeLayer.Nodes[previousNode._id]
    if typeof newNode == 'undefined' or newNode == null
      return
    @nodeDetail.dataVar.set(newNode)

  # Clears the current path details and renders the current path's details
  #
  # @param [GritsPath] path - path for which details will be displayed
  showPathDetails: (path) ->
    self = this
    $('.path-detail').empty()
    $('.path-detail').hide()
    div = $('.path-detail')[0]
    Blaze.renderWithData Template.pathDetails, path, div
    $('.path-detail').show()
    $('.path-detail-close').off().on('click', (e) ->
        self.hidePathDetails()
    )

  # Clears the current path details and renders the current path's details
  #
  # @param [MapPath] path - path for which details will be displayed
  hidePathDetails: ->
    $('.path-detail').empty()
    $('.path-detail').hide()
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

    $(".path-detail-close").on 'click', ->
      $('.path-detail').hide()
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
    levelFilter: () ->
      val = $("#connectednessLevels").val()
      Meteor.gritsUtil.removeQueryCriteria(55)
      if val isnt '' and val isnt '0'
        Meteor.gritsUtil.addQueryCriteria({'critId': 55, 'key': 'flightNumber', 'value': {$ne:-val}})
      return
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

  # onSubscriptionReady
  #
  # This method is triggered with the 'flightsByQuery' subscription onReady
  # callback.  It gets the new flights from the collection and updates the
  # existing nodes (airports) and paths (flights).
  onSubscriptionReady: ->
    self = this

    tflights = Flights.find().fetch()

    ###
    tlevArray = []
    apCodes = []
    for flight of tflights
      apCodes.push tflights[flight].arrivalAirport._id
      apCodes.push tflights[flight].departureAirport._id
      tlevArray.push tflights[flight]._id

    Meteor.gritsUtil.pathLevelIds[Meteor.gritsUtil.currentLevel] = tlevArray
    if Meteor.gritsUtil.currentLevel is parseInt($("#connectednessLevels").val())
      Meteor.gritsUtil.currentLevel = 1
      Meteor.gritsUtil.pathLevelIds = []
    else if $("#connectednessLevels").val() is '' or $("#connectednessLevels").val() is '0'
      Meteor.gritsUtil.currentLevel = 1
      Meteor.gritsUtil.pathLevelIds = []
    else
      Meteor.gritsUtil.currentLevel++
      Meteor.gritsUtil.applyFilters()
      Meteor.gritsUtil.removeQueryCriteria(11)
      Meteor.gritsUtil.addQueryCriteria({'critId': 11, 'key': 'departureAirport._id', 'value': {$in: apCodes}})
      Session.set 'query', Meteor.gritsUtil.getQueryCriteria()
      return
    ###

    # This may run prior to initializing the leaflet map; check for undefined
    # and return
    if typeof self.heatmap == 'undefined'
      return

    count = 0
    self.heatmap.clear()
    self.pathLayer.clear()
    self.nodeLayer.clear()
    processQueue = async.queue(((flight, callback) ->
      self.heatmap.convertFlight(flight)
      nodes = self.nodeLayer.convertFlight(flight)
      self.pathLayer.convertFlight(flight, self.currentLevel, nodes[0], nodes[1])
      count++
      async.nextTick ->
        if !(count % 100)
          # let the UI update every x iterations
          # the heatmap isn't visible by default so draw can happen in the drain
          self.pathLayer.draw()
          self.nodeLayer.draw()
          Session.set('loadedRecords', count)
        callback()
    ), 1)

    # callback method for when all items within the queue are processed
    processQueue.drain = ->
      self.heatmap.draw()
      self.pathLayer.draw()
      self.nodeLayer.draw()
      Session.set('loadedRecords', count)
      Session.set('isUpdating', false)

    processQueue.push(tflights);

  # onMoreSubscriptionsReady
  #
  # This method is triggered when the [More..] button is pressed in continuation
  # of a limit/offset query
  onMoreSubscriptionsReady: ->
    return
    ###
    self = this

    # sync the heatmap
    if !(_.isUndefined(Meteor.gritsUtil.heatmap) or _.isNull(Meteor.gritsUtil.heatmap))
      Meteor.gritsUtil.heatmap.convertFlightDestinationsToPoints(Flights.find())
      try
        Meteor.gritsUtil.heatmap.draw()
      catch e
        console.error e.message

    # populate the node layer
    self.nodeLayer.convertFlightToNodes(Flights, (err, res) ->
      self.nodeLayer.draw()
      Session.set('isUpdating', false)
    )

    self.pathLayer.convertFlightToPaths(Flights.find(), (err, res) ->
      self.pathLayer.draw()
      Session.set('isUpdating', false)
    )
    return
    ###
