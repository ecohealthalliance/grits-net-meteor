_ignoreFields = ['limit', 'offset'] # fields that are used for maintaining state but will be ignored when sent to the server
_validFields = ['departure', 'effectiveDate', 'discontinuedDate', 'limit', 'offset']
_validOperators = ['$gte', '$gt', '$lte', '$lt', '$eq', '$ne', '$in', '$near', null]
_state = null # keeps track of the query string state
# local/private minimongo collection
_Collection = new (Mongo.Collection)(null)
# local/private Astronomy model for maintaining filter criteria
_Filter = Astro.Class(
  name: 'FilterCriteria'
  collection: _Collection
  transform: true
  fields: ['key', 'operator', 'value']
  validators: {
    key: [
        Validators.required(),
        Validators.string()
    ],
    operator: [
        Validators.required(),
        Validators.string(),
        Validators.choice(_validOperators)
    ],
    value: Validators.required()
  }
)

# GritsFilterCriteria, this object provides the interface for
# accessing the UI filter box. The setter methods may be called
# programmatically or the reactive var can be set by event handers
# within the UI.  The entire object maintains its own state.
#
# @note exports as a 'singleton'
class GritsFilterCriteria
  constructor: () ->
    self = this

    # reactive var used to update the UI when the query state has changed
    self.stateChanged = new ReactiveVar(null)

    # setup an instance variable that contains todays date.  This will be used
    # to set the initial Start and End dates to the Operating Date Range
    now = new Date()
    month = now.getMonth()
    date = now.getDate()
    year = now.getFullYear()
    self._today = new Date(year, month, date)
    # this._baseState keeps track of the initial plugin state after any init
    # methods have run
    self._baseState = {}

    # processing queue
    self._queue = null

    # reactive vars to track form binding
    #   departures
    self.departures = new ReactiveVar([])
    self.trackDepartures()

    #   operatingDateRangeStart
    self.operatingDateRangeStart = new ReactiveVar(null)
    self.trackOperatingDateRangeStart()
    #   operatingDateRangeEnd
    self.operatingDateRangeEnd = new ReactiveVar(null)
    self.trackOperatingDateRangeEnd()

    #   limit
    self.limit = new ReactiveVar(1000)
    self.trackLimit()

    #   offset
    self.offset = new ReactiveVar(0)

    # airportCounts
    # during a simulation the airports are counted to update the heatmap
    self.airportCounts = {}

    return
  # initialize the start date of the filter 'discontinuedDate'
  #
  # @return [String] dateString, formatted MM/DD/YY
  initStart: () ->
    self = this
    start = self._today
    self.createOrUpdate('discontinuedDate', {key: 'discontinuedDate', operator: '$gte', value: start})
    query = @getQueryObject()
    # update the state logic for the indicator
    _state = JSON.stringify(query)
    self._baseState = JSON.stringify(query)
    month = start.getMonth() + 1
    date = start.getDate()
    year = start.getFullYear().toString().slice(2,4)
    year = start.getFullYear()
    yearStr = year.toString().slice(2,4)
    self.operatingDateRangeStart.set(new Date(year, month, date))
    return "#{month}/#{date}/#{yearStr}"
  # initialize the end date through the 'effectiveDate' filter
  #
  # @return [String] dateString, formatted MM/DD/YY
  initEnd: () ->
    self = this
    end = moment(@_today).add(7, 'd').toDate()
    self.createOrUpdate('effectiveDate', {key: 'effectiveDate', operator: '$lte', value: end})
    # get the query object
    query = self.getQueryObject()
    # update the state logic for the indicator
    _state = JSON.stringify(query)
    self._baseState = JSON.stringify(query)
    month = end.getMonth() + 1
    date = end.getDate()
    year = end.getFullYear()
    yearStr = year.toString().slice(2,4)
    self.operatingDateRangeEnd.set(new Date(year, month, date))
    return "#{month}/#{date}/#{yearStr}"
  # initialize the limit through the 'effectiveDate' filter
  #
  # @return [Integer] limit
  initLimit: () ->
    self = this
    initLimit = self.limit.get()
    self.setLimit(initLimit)
    self._baseState = JSON.stringify(self.getQueryObject())
    return initLimit
  # Creates a new filter criteria and adds it to the collection or updates
  # the collection if it already exists
  #
  # @param [String] id, the name of the filter criteria
  # @return [Object] Astronomy model 'FilterCriteria'
  createOrUpdate: (id, fields) ->
    self = this
    if _.indexOf(_validFields, id) < 0
      throw new Error('Invalid filter: ' + id)
    obj = _Collection.findOne({_id: id})
    if obj
      obj.set(fields)
      if obj.validate() == false
        throw new Error(_.values(obj.getValidationErrors()))
      obj.save()
      return obj
    else
      _.extend(fields, {_id: id})
      obj = new _Filter(fields)
      if obj.validate() == false
        throw new Error(_.values(obj.getValidationErrors()))
      obj.save()
      return obj
  # removes a FilterCriteria from the collection
  #
  # @param [String] id, the name of the filter criteria
  # @optional [Function] cb, the callback method if removing async
  remove: (id, cb) ->
    self = this
    obj = _Collection.findOne({_id: id})
    if obj and cb
      obj.remove(cb)
      return
    if obj
      return obj.remove()
    else
      return 0
  # returns the query object used to filter the server-side collection
  #
  # @return [Object] query, a mongoDB query object
  getQueryObject: () ->
    self = this
    criteria = _Collection.find({})
    result = {}
    criteria.forEach((filter) ->
      value = {}
      k = filter.get('key')
      o = filter.get('operator')
      v = filter.get('value')
      if _.indexOf(['$eq'], o) >= 0
        value = v
      else
        value[o] = v
      result[k] = value
    )
    return result
  # compares the current state vs. the original/previous state
  compareStates: () ->
    self = this
    # postone execution to avoid 'flash' for the fast draw case.  this happens
    # when the user clicks a node or presses enter on the search and the
    # draw completes faster than the debounce timeout
    async.nextTick(() ->
      current = self.getCurrentState()
      if current != _state
        # do not notifiy on an empty query or the base state
        if current == "{}" || current == self._baseState
          self.stateChanged.set(false)

        else
          self.stateChanged.set(true)
          # disable [More...] button when filter has changed
          $('#loadMore').prop('disabled', true)
      else
        self.stateChanged.set(false)
    )
    return
  # gets the current state of the filter
  #
  # @return [String] the query object JSON.strigify
  getCurrentState: () ->
    self = this
    query = self.getQueryObject()
    return JSON.stringify(query)
  # get the original/previous state of the filter
  #
  # @return [String] the query object JSON.strigify
  getState: () ->
    _state
  # sets the original/previous state of the filter, this method will read the
  # current query object and store is as a JSON string
  setState: () ->
    self = this
    query = self.getQueryObject()
    _state = JSON.stringify(query)
    return
  # process the results of the meteor methods to get flights
  #
  # @param [Array] flights, an Array of flights to process
  # @param [Integer] offset, the offset of the query
  process: (flights, offset) ->
    self = this
    if self._queue != null
      self._queue.kill()
      async.nextTick(() ->
        self._queue = null
      )

    map = Template.gritsMap.getInstance()
    layerGroup = GritsLayerGroup.getCurrentLayerGroup()
    heatmapLayerGroup = Template.gritsMap.getInstance().getGritsLayerGroup(GritsConstants.HEATMAP_GROUP_LAYER_ID)
    # if the offset is equal to zero, clear the layers
    if offset == 0
      layerGroup.reset()
      heatmapLayerGroup.reset()

    count = Session.get(GritsConstants.SESSION_KEY_LOADED_RECORDS)

    throttleDraw = _.throttle(->
      layerGroup.draw()
      heatmapLayerGroup.draw()
    , 500)

    self._queue = async.queue(((flight, callback) ->
      # convert the flight into a node/path
      layerGroup.convertFlight(flight, 1, self.departures.get())
      # update the layer
      throttleDraw()
      # update the counter
      Session.set(GritsConstants.SESSION_KEY_LOADED_RECORDS , ++count)
      # done processing
      async.nextTick(-> callback())
    ), 4)

    # final method for when all items within the queue are processed
    self._queue.drain = ->
      layerGroup.finish()
      heatmapLayerGroup.finish()
      Session.set(GritsConstants.SESSION_KEY_LOADED_RECORDS, count)
      Session.set(GritsConstants.SESSION_KEY_IS_UPDATING, false)

    # add the flights to thet queue which will start processing
    self._queue.push(flights)
    return
  # applies the filter but does not reset the offset
  #
  # @param [Function] cb, the callback function
  more: (cb) ->
    self = this

    # applying the filter is always EXPLORE mode
    Session.set(GritsConstants.SESSION_KEY_MODE, GritsConstants.MODE_EXPLORE)

    query = self.getQueryObject()
    if _.isUndefined(query) or _.isEmpty(query)
      toastr.error(i18n.get('toastMessages.departureRequired'))
      Session.set(GritsConstants.SESSION_KEY_IS_UPDATING, false)
      return

    if !query.hasOwnProperty('departureAirport._id')
      toastr.error(i18n.get('toastMessages.departureRequired'))
      Session.set(GritsConstants.SESSION_KEY_IS_UPDATING, false)
      return

    # set the state
    self.setState()
    self.compareStates()

    # set the arguments
    limit = query.limit
    offset = self.offset.get()

    # remove the ignoreFields from the query
    _.each(_ignoreFields, (field) ->
      if query.hasOwnProperty(field)
        delete query[field]
    )

    # handle any metaNodes
    tokens = query['departureAirport._id']['$in']
    modifiedTokens = []
    _.each(tokens, (token) ->
      if (token.indexOf(GritsMetaNode.PREFIX) >= 0)
        node = GritsMetaNode.find(token)
        if node == null
          return
        if (node.hasOwnProperty('_children'))
          modifiedTokens = _.union(modifiedTokens, _.pluck(node._children, '_id'))
      else
        modifiedTokens = _.union(modifiedTokens, token)
    )
    query['departureAirport._id']['$in'] = modifiedTokens

    # show the loading indicator and call the server-side method
    Session.set(GritsConstants.SESSION_KEY_IS_UPDATING, true)
    async.auto({
      # get the totalRecords count first
      'getCount': (callback, result) ->
        Meteor.call('countFlightsByQuery', query, (err, totalRecords) ->
          if (err)
            callback(err)
            return

          if Meteor.gritsUtil.debug
            console.log 'totalRecords: ', totalRecords

          Session.set(GritsConstants.SESSION_KEY_TOTAL_RECORDS, totalRecords)
          callback(null, totalRecords)
        )
      # when count is finished, get the flights if greater than 0
      'getFlights': ['getCount', (callback, result) ->
        totalRecords = result.getCount

        if totalRecords.length <= 0
          toastr.info(i18n.get('toastMessages.noResults'))
          Session.set(GritsConstants.SESSION_KEY_IS_UPDATING, false)
          callback(null)
          return

        Meteor.call('flightsByQuery', query, limit, offset, (err, flights) ->
          if (err)
            callback(err)
            return

          if _.isUndefined(flights) || flights.length <= 0
            toastr.info(i18n.get('toastMessages.noResults'))
            Session.set(GritsConstants.SESSION_KEY_IS_UPDATING, false)
            callback(null, [])
            return

          callback(null, flights)
        )
      ]
    }, (err, result) ->
      if err
        Meteor.gritsUtil.errorHandler(err)
        return
      # if there hasn't been any errors, getCount and getFlights will
      # have completed
      flights = result.getFlights
      # call the original callback function if its defined
      if cb && _.isFunction(cb)
        cb(null, flights)
      # process the flights
      self.process(flights, offset)
      return
    )
    return
  # applies the filter; resets the offset, loadedRecords, and totalRecords
  #
  # @param [Function] cb, the callback function
  apply: (cb) ->
    self = this
    self.offset.set(0)
    # allow the reactive var to be set before continue
    async.nextTick(() ->
      # reset the loadedRecords and totalRecords
      Session.set(GritsConstants.SESSION_KEY_LOADED_RECORDS, 0)
      Session.set(GritsConstants.SESSION_KEY_TOTAL_RECORDS, 0)
      # re-enable the loadMore button when a new filter is applied
      $('#loadMore').prop('disabled', false)
      # pass the callback function if its defined
      if cb && _.isFunction(cb)
        self.more(cb)
      else
        self.more()
    )
    return
  # sets the 'start' date from the filter and updates the filter criteria
  #
  # @param [Object] date, Date object or null to clear the criteria
  setOperatingDateRangeStart: (date) ->
    self = this

    # do not allow this to run prior to jQuery/DOM
    if _.isUndefined($)
      return
    discontinuedDatePicker = Template.gritsSearch.getDiscontinuedDatePicker()
    if _.isNull(discontinuedDatePicker)
      return

    discontinuedDate = discontinuedDatePicker.data('DateTimePicker').date()

    if _.isNull(date) || _.isNull(discontinuedDate)
      if _.isEqual(date, discontinuedDate)
        self.remove('discontinuedDate')
      else
        discontinuedDatePicker.data('DateTimePicker').date(null)
        self.operatingDateRangeStart.set(null)
      return

    if _.isEqual(date.toISOString(), discontinuedDate.toISOString())
      # the reactive var is already set, change is from the UI
      self.createOrUpdate('discontinuedDate', {key: 'discontinuedDate', operator: '$gte', value: discontinuedDate})
    else
      discontinuedDatePicker.data('DateTimePicker').date(date)
      self.operatingDateRangeStart.set(date)
    return
  trackOperatingDateRangeStart: () ->
    self = this
    Tracker.autorun ->
      obj = self.operatingDateRangeStart.get()
      self.setOperatingDateRangeStart(obj)
      async.nextTick(() ->
        self.compareStates()
      )
    return
  # sets the 'end' date from the filter and updates the filter criteria
  #
  # @param [Object] date, Date object or null to clear the criteria
  setOperatingDateRangeEnd: (date) ->
    self = this

    # do not allow this to run prior to jQuery/DOM
    if _.isUndefined($)
      return
    effectiveDatePicker = Template.gritsSearch.getEffectiveDatePicker()
    if _.isNull(effectiveDatePicker)
      return

    effectiveDate = effectiveDatePicker.data('DateTimePicker').date()

    if _.isNull(date) || _.isNull(effectiveDate)
      if _.isEqual(date, effectiveDate)
        self.remove('effectiveDate')
      else
        effectiveDatePicker.data('DateTimePicker').date(null)
        self.operatingDateRangeEnd.set(null)
      return

    if _.isEqual(date.toISOString(), effectiveDate.toISOString())
      # the reactive var is already set, change is from the UI
      self.createOrUpdate('effectiveDate', {key: 'effectiveDate', operator: '$lte', value: effectiveDate})
    else
      effectiveDatePicker.data('DateTimePicker').date(date)
      self.operatingDateRangeEnd.set(date)
    return
  trackOperatingDateRangeEnd: () ->
    self = this
    Tracker.autorun ->
      obj = self.operatingDateRangeEnd.get()
      self.setOperatingDateRangeEnd(obj)
      async.nextTick(() ->
        self.compareStates()
      )
    return
  # sets the departure input on the UI to the 'code'
  # specified, as well as, updating the underlying FilterCriteria.
  #
  # @param [String] code, an airport IATA code
  # @see http://www.iata.org/Pages/airports.aspx
  setDepartures: (code) ->
    self = this

    # do not allow this to run prior to jQuery/DOM
    if _.isUndefined($)
      return
    if _.isUndefined(code)
      throw new Error('A code must be defined or null.')

    if _.isEqual(self.departures.get(), code)
      # the call is from the UI
      if _.isNull(code)
        self.remove('departure')
        return
      if _.isEmpty(code)
        self.remove('departure')
        return
      if _.isArray(code)
        capsCodes = []
        for _id in code
          capsCodes.push _id.toUpperCase()
        if !_.isEqual(capsCodes, code)
          Template.gritsSearchAndAdvancedFiltration.getDepartureSearchMain().tokenfield('setTokens', capsCodes)
        self.createOrUpdate('departure', {key: 'departureAirport._id', operator: '$in', value: capsCodes})
      else
        self.createOrUpdate('departure', {key: 'departureAirport._id', operator: '$in', value: [code]})
    else
      if _.isNull(code)
        Template.gritsSearch.getDepartureSearchMain().tokenfield('setTokens', [])
        self.departures.set([])
        return
      if _.isEmpty(code)
        Template.gritsSearch.getDepartureSearchMain().tokenfield('setTokens', [])
        self.departures.set([])
        return
      if _.isArray(code)
        Template.gritsSearch.getDepartureSearchMain().tokenfield('setTokens', code)
        self.departures.set(code)
      else
        Template.gritsSearch.getDepartureSearchMain().tokenfield('setTokens', [code])
        self.departures.set([code])
    return
  trackDepartures: () ->
    self = this
    Tracker.autorun ->
      obj = self.departures.get()
      if _.isEmpty(obj)
        # checks are necessary as Tracker autorun will fire before the DOM
        # is ready and the Template.gritsMap.onRenered is called
        if !(_.isUndefined(Template.gritsMap) || _.isUndefined(Template.gritsMap.getInstance))
          map = Template.gritsMap.getInstance()
          if !_.isNull(map)
            layerGroup = GritsLayerGroup.getCurrentLayerGroup()
            # clears the sub-layers and resets the layer group
            if layerGroup != null
              layerGroup.reset()
      self.setDepartures(obj)
      async.nextTick(() ->
        self.compareStates()
      )
    return
  # sets the limit input on the UI to the 'value'
  # specified, as well as, updating the underlying FilterCriteria.
  #
  # @note This is not part of the query, but is included to maintain the UI state.  Upon 'apply' the value is deleted from the query and used as an arguement to the server-side method
  # @param [Integer] value
  setLimit: (value) ->
    self = this

    # do not allow this to run prior to jQuery/DOM
    if _.isUndefined($)
      return

    if _.isUndefined(value)
      throw new Error('Limit must be defined.')

    if _.isEqual(self.limit.get(), value)
      if _.isNull(value)
        self.remove('limit')
      else
        val = Math.floor(parseInt(value, 10))
        if isNaN(val) or val < 1
          throw new Error('Limit must be positive')
        self.createOrUpdate('limit', {key: 'limit', operator: '$eq', value: val})
    else
      self.limit.set(value)
    return
  trackLimit: () ->
    self = this
    Tracker.autorun ->
      obj = self.limit.get()
      try
        self.setLimit(obj)
        async.nextTick(() ->
          self.compareStates()
        )
      catch e
        Meteor.gritsUtil.errorHandler(e)
    return
  # sets the offest as calculated by the current query that has more results
  # than the limit
  #
  # @note This is not part of the query, but is included to maintain the UI state.  Upon 'apply' the value is deleted from the query and used as an arguement to the server-side method
  setOffset: () ->
    self = this
    # do not allow this to run prior to jQuery/DOM
    if _.isUndefined($)
      return

    totalRecords = Session.get(GritsConstants.SESSION_KEY_TOTAL_RECORDS)
    loadedRecords = Session.get(GritsConstants.SESSION_KEY_LOADED_RECORDS)

    if (loadedRecords < totalRecords)
      self.offset.set(loadedRecords)
    else
      self.offset.set(0)
    return
  # returns a unique list of tokens from the search bar
  getOriginIds: () ->
    self = this
    return _.chain(self.departures.get())
      .map (originId)->
        if originId.startsWith(GritsMetaNode.PREFIX)
          return GritsMetaNode.find(originId).getAirportIds()
        else
          [originId]
      .flatten()
      .uniq()
      .value()
  # handle setup of subscription to SimulatedIteneraries and process the results
  processSimulation: (simPas, simId) ->
    self = this
    # get the heatmapLayerGroup
    heatmapLayerGroup = Template.gritsMap.getInstance().getGritsLayerGroup(GritsConstants.HEATMAP_GROUP_LAYER_ID)
    # get the current mode groupLayer
    layerGroup = GritsLayerGroup.getCurrentLayerGroup()
    if layerGroup == null
      return

    # reset the layers/counters
    layerGroup.reset()
    heatmapLayerGroup.reset()
    loaded = 0
    # initialize the status-bar counter
    Session.set(GritsConstants.SESSION_KEY_LOADED_RECORDS, loaded)
    # reset the airportCounts
    self.airportCounts = {}

    originIds = self.getOriginIds()
    _updateHeatmap = _.throttle(->
      Heatmaps.remove({})
      # map the airportCounts object to one with percentage values
      airportPercentages = _.object([key, val / loaded] for key, val of self.airportCounts)
      # key the heatmap to the departure airports so it can be filtered
      # out if the query changes.
      airportPercentages._id = originIds.sort().join("")
      Heatmap.createFromDoc(airportPercentages, Meteor.gritsUtil.airportsToLocations)
    , 500)

    _throttledDraw = _.throttle(->
      layerGroup.draw()
      heatmapLayerGroup.draw()
    , 500)

    Meteor.subscribe('SimulationItineraries', simId)
    options =
      transform: null

    _doWork = (id, fields) ->
      if self.airportCounts[fields.destination]
        self.airportCounts[fields.destination]++
      else
        self.airportCounts[fields.destination] = 1
      loaded += 1
      layerGroup.convertItineraries(fields, fields.origin)
      # update the simulatorProgress bar
      if simPas > 0
        progress = Math.ceil((loaded / simPas) * 100)
        Template.gritsSearch.simulationProgress.set(progress)
        Session.set(GritsConstants.SESSION_KEY_LOADED_RECORDS, loaded)
      if loaded == simPas
        #finaldraw
        Template.gritsSearch.simulationProgress.set(100)
        Session.set(GritsConstants.SESSION_KEY_LOADED_RECORDS, loaded)
        _updateHeatmap()
        layerGroup.finish()
        heatmapLayerGroup.finish()
      else
        _updateHeatmap()
        _throttledDraw()

    Itineraries.find({'simulationId': simId}, options).observeChanges({
      # UI freeze does not occur
      added: Meteor.gritsUtil.smoothRate (id, fields) ->
        _doWork(id, fields)
    })
    return
  # starting a simulation
  startSimulation: (simPas, startDate, endDate) ->
    self = this
    departures = self.departures.get()
    if departures.length == 0
      toastr.error(i18n.get('toastMessages.departureRequired'))
      return

    # switch mode
    Session.set(GritsConstants.SESSION_KEY_MODE, GritsConstants.MODE_ANALYZE)

    # let the user know the simulation started
    Template.gritsSearch.simulationProgress.set(1)

    Meteor.call('startSimulation', simPas, startDate, endDate, self.getOriginIds(), (err, res) ->
      # handle any errors
      if err
        Meteor.gritsUtil.errorHandler(err)
        console.error(err)
        return
      if res.hasOwnProperty('error')
        Meteor.gritsUtil.errorHandler(res)
        console.error(res)
        return

      # set the reactive var on the template
      Template.gritsDataTable.simId.set(res.simId)

      # update the url
      FlowRouter.go('/simulation/'+res.simId)

      # set the status-bar total counter
      Session.set(GritsConstants.SESSION_KEY_TOTAL_RECORDS, simPas)

      # setup parameters for the subscription to SimulationItineraries
      limit = self.limit.get()
      skip = 0 # clicking on start risk analysis always starts with zero
      self.processSimulation(simPas, res.simId)
      return
    )

GritsFilterCriteria = new GritsFilterCriteria() # exports as a singleton
