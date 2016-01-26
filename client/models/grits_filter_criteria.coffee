_debounceInMilliseconds = 2000 # time to delay the auto-submission of the filter
_ignoreFields = ['levels', 'limit', 'offset'] # fields that are used for maintaining state but will be ignored when sent to the server
_validFields = ['weeklyFrequency', 'stops', 'seats', 'departure', 'arrival', 'levels', 'effectiveDate', 'discontinuedDate', 'levels', 'limit']
_validOperators = ['$gte', '$gt', '$lte', '$lt', '$eq', '$ne', '$in', '$near', null]
_state = null # keeps track of the query string state
# local/private minimongo collection
_Collection = new (Mongo.Collection)(null)
# local/private Astronomy model for maintaining filter criteria
_Filter = Astro.Class(
  name: 'FilterCriteria'
  collection: _Collection
  transform: true
  fields: ['key', 'operator', 'value', 'operator2', 'value2']
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

    # debounce wrapper to limit the amount of calls to this function within
    # the specified time period
    self.autoApply = _.debounce(self.autoApply, _debounceInMilliseconds)

    # lastFlightId used for query with more than one level
    self.lastFlightId = null

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

    # reactive vars to track form binding
    #   departures
    self.departures = new ReactiveVar([])
    self.trackDepartures()
    #   arrivals
    self.arrivals = new ReactiveVar([])
    self.trackArrivals()
    #   weeklyFrequency
    self.weeklyFrequency = new ReactiveVar(null)
    self.trackWeeklyFrequency()
    #   stops
    self.stops = new ReactiveVar(null)
    self.trackStops()
    #   seats
    self.seats = new ReactiveVar(null)
    self.trackSeats()
    #   operatingDateRangeStart
    self.operatingDateRangeStart = new ReactiveVar(null)
    self.trackOperatingDateRangeStart()
    #   operatingDateRangeEnd
    self.operatingDateRangeEnd = new ReactiveVar(null)
    self.trackOperatingDateRangeEnd()
    #   levels
    self.levels = new ReactiveVar(1)
    self.trackLevels()
    #   limit
    self.limit = new ReactiveVar(1000)
    self.trackLimit()

    #   offset
    self.offset = new ReactiveVar(0)
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
  # initialize the end date through the 'effectiveDate' filter
  #
  # @return [Integer] level
  initLevels: () ->
    self = this
    initLevels = self.levels.get()
    self.setLevels(initLevels)
    self._baseState = JSON.stringify(self.getQueryObject())
    return initLevels
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
  # @note must be one of 'day1', 'day2', 'day3', 'day4', 'day5', 'day6', 'day7', 'weeklyFrequency', 'stops', 'seats', 'departure', 'arrival', 'levels'
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
  # @note must be one of 'day1', 'day2', 'day3', 'day4', 'day5', 'day6', 'day7', 'weeklyFrequency', 'stops', 'seats', 'departure', 'arrival', 'levels'
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
      o2 = filter.get('operator2')
      v2 = filter.get('value2')
      if _.indexOf(['$eq'], o) >= 0
        value = v
      else
        value[o] = v
        if o2 isnt null
          value[o2] = v2
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
          # checks are necessary as Tracker autorun will fire before the DOM
          # is ready and the Template.gritsMap.onRenered is called
          if !(_.isUndefined(Template.gritsMap) || _.isNull(Template.gritsMap))
            if !_.isUndefined(Template.gritsMap.getInstance)
              map = Template.gritsMap.getInstance()
              if !_.isNull(map)
                # clear the node/paths
                nodeLayer = map.getGritsLayer('Nodes')
                pathLayer = map.getGritsLayer('Paths')
                nodeLayer.clear()
                pathLayer.clear()
        else
          self.stateChanged.set(true)

          # auto-apply the filter
          self.autoApply()

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
    map = Template.gritsMap.getInstance()
    nodeLayer = map.getGritsLayer('Nodes')
    pathLayer = map.getGritsLayer('Paths')

    # if the offset is equal to zero, clear the layers
    if offset == 0
      nodeLayer.clear()
      pathLayer.clear()

    count = Session.get('grits-net-meteor:loadedRecords')
    processQueue = async.queue(((flight, callback) ->
      nodes = nodeLayer.convertFlight(flight, 1, self.departures.get())
      pathLayer.convertFlight(flight, 1, nodes[0], nodes[1])
      async.nextTick ->
        if !(count % 100)
          nodeLayer.draw()
          pathLayer.draw()
        Session.set('grits-net-meteor:loadedRecords', ++count)
        callback()
    ), 4)

    # final method for when all items within the queue are processed
    processQueue.drain = ->
      nodeLayer.draw()
      nodeLayer.hasLoaded.set(true)
      pathLayer.draw()
      pathLayer.hasLoaded.set(true)
      Session.set('grits-net-meteor:loadedRecords', count)
      Session.set('grits-net-meteor:isUpdating', false)

    # add the flights to thet queue which will start processing
    processQueue.push(flights)
    return
  # applies the filter but does not reset the offset
  #
  # @param [Function] cb, the callback function
  more: (cb) ->
    self = this
    query = self.getQueryObject()
    if _.isUndefined(query) or _.isEmpty(query)
      toastr.error('The filter requires at least one Departure')
      Session.set('grits-net-meteor:isUpdating', false)
      return

    if !query.hasOwnProperty('departureAirport._id')
      toastr.error('The filter requires at least one Departure')
      Session.set('grits-net-meteor:isUpdating', false)
      return

    # set the state
    self.setState()
    self.compareStates()

    # set the arguments
    levels = query.levels
    limit = query.limit
    lastId = self.lastFlightId
    offset = self.offset.get()

    # remove the ignoreFields from the query
    _.each(_ignoreFields, (field) ->
      if query.hasOwnProperty(field)
        delete query[field]
    )

    if levels > 1
      origin = Template.gritsSearchAndAdvancedFiltration.getOrigin()
      if !_.isNull(origin)
        # show the loading indicator and call the server-side method
        Session.set 'grits-net-meteor:isUpdating', true
        if _.isNull(self.lastFlightId)
          Meteor.call('getFlightsByLevel', query, levels, origin, limit, (err, res) ->
            if Meteor.gritsUtil.debug
              console.log('levels:res: ', res)
            Session.set 'grits-net-meteor:totalRecords', res[1]
            if !_.isUndefined(res[2]) and !_.isEmpty(res[2])
              self.lastFlightId = res[2]
            self.process(res[0], offset)
          )
        else
          Meteor.call('getMoreFlightsByLevel', query, levels, origin, limit, self.lastFlightId, (err, res) ->
            if Meteor.gritsUtil.debug
              console.log('levels:res: ', res)
            Session.set 'grits-net-meteor:totalRecords', res[1]
            if !_.isUndefined(res[2]) and !_.isEmpty(res[2])
              self.lastFlightId = res[2]
            self.process(res[0], offset)
          )
        return
      return

    # show the loading indicator and call the server-side method
    Session.set 'grits-net-meteor:isUpdating', true
    async.auto({
      # get the totalRecords count first
      'getCount': (callback, result) ->
        Meteor.call('countFlightsByQuery', query, (err, totalRecords) ->
          if (err)
            callback(err)
            return

          if Meteor.gritsUtil.debug
            console.log 'totalRecords: ', totalRecords

          if levels <= 1
            Session.set 'grits-net-meteor:totalRecords', totalRecords

          callback(null, totalRecords)
        )
      # when count is finished, get the flights if greater than 0
      'getFlights': ['getCount', (callback, result) ->
        totalRecords = result.getCount

        if totalRecords.length <= 0
          toastr.info('The filter did not return any results')
          Session.set('grits-net-meteor:isUpdating', false)
          callback(null)
          return

        Meteor.call('flightsByQuery', query, limit, offset, (err, flights) ->
          if (err)
            callback(err)
            return

          if _.isUndefined(flights) || flights.length <= 0
            toastr.info('The filter did not return any results')
            Session.set('grits-net-meteor:isUpdating', false)
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
    self.lastFlightId = null
    self.offset.set(0)
    # allow the reactive var to be set before continue
    async.nextTick(() ->
      # reset the loadedRecords and totalRecords
      Session.set('grits-net-meteor:loadedRecords', 0)
      Session.set('grits-net-meteor:totalRecords', 0)
      $('#loadMore').prop('disabled', false)
      # re-enable the loadMore button when a new filter is applied
      $('#loadMore').prop('disabled', false)
      # pass the callback function if its defined
      if cb && _.isFunction(cb)
        self.more(cb)
      else
        self.more()
    )
    return
  # automatically applies the filter; resets the offset, loadedRecords, and
  # totalRecords
  #
  # @note this method is debounced in the constructor
  autoApply: () ->
    self = this
    if !Session.get('grits-net-meteor:isUpdating')
      self.apply()
  # sets the 'start' date from the filter and updates the filter criteria
  #
  # @param [Object] date, Date object or null to clear the criteria
  setOperatingDateRangeStart: (date) ->
    self = this

    # do not allow this to run prior to jQuery/DOM
    if _.isUndefined($)
      return
    discontinuedDatePicker = Template.gritsSearchAndAdvancedFiltration.getDiscontinuedDatePicker()
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
      async.nextTick(()->
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
    effectiveDatePicker = Template.gritsSearchAndAdvancedFiltration.getEffectiveDatePicker()
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
      async.nextTick(()->
        self.compareStates()
      )
    return
  # sets the weeklyFrequency input on the UI to the 'operator' and 'value'
  # specified, as well as, updating the underlying FilterCriteria.
  #
  # @param [String] operator
  # @param [Integer] value
  setWeeklyFrequency: (operator, value) ->
    self = this

    # do not allow this to run prior to jQuery/DOM
    if _.isUndefined($)
      return
    if _.indexOf(_validOperators, operator) < 0
      throw new Error('Invalid operator: ', operator)
    if _.isUndefined(value)
      throw new Error('A value must be defined or null.')

    if _.isEqual(self.weeklyFrequency.get(), {value: value, operator: operator})
      # the reactive var is already set, change is from the UI
      if _.isNull(value)
        self.remove('weeklyFrequency')
      else
        self.createOrUpdate('weeklyFrequency', {key: 'weeklyFrequency', operator: operator, value: value})
    else
      self.weeklyFrequency.set({'value': value, 'operator', operator})
      $('#weeklyFrequencyOperator').val(operator)
    return
  trackWeeklyFrequency: () ->
    self = this
    Tracker.autorun ->
      obj = self.weeklyFrequency.get()
      if _.isNull(obj)
        return
      self.setWeeklyFrequency(obj.operator, obj.value)
      async.nextTick(()->
        self.compareStates()
      )
    return
  # sets the stops input on the UI to the 'operator' and 'value'
  # specified, as well as, updating the underlying FilterCriteria.
  #
  # @param [String] operator
  # @param [Integer] value
  setStops: (operator, value, operator2, value2) ->
    self = this

    # do not allow this to run prior to jQuery/DOM
    if _.isUndefined($)
      return
    if _.indexOf(_validOperators, operator) < 0
      throw new Error('Invalid operator: ', operator)
    if _.isUndefined(value)
      throw new Error('A value must be defined or null.')
    # the call to change did not come from the UI
    if _.isEqual(self.stops.get(), {value: value, operator: operator})
      # the reactive var is already set, change is from the UI
      if _.isNull(value)
        self.remove('stops')
      else
        self.createOrUpdate('stops', {key: 'stops', operator: operator, value: value, operator2: operator2, value2: value2})
    else
      self.stops.set({'value': value, 'operator': operator})
      $('#stopsOperator').val(operator)
    return
  trackStops: () ->
    self = this
    Tracker.autorun ->
      obj = self.stops.get()
      if _.isNull(obj)
        return
      self.setStops(obj.operator, obj.value, obj.operator2, obj.value2)
      async.nextTick(()->
        self.compareStates()
      )
    return
  # sets the seats input on the UI to the 'operator' and 'value'
  # specified, as well as, updating the underlying FilterCriteria.
  #
  # @param [String] operator
  # @param [Integer] value
  setSeats: (operator, value, operator2, value2) ->
    self = this

    # do not allow this to run prior to jQuery/DOM
    if _.isUndefined($)
      return
    if _.indexOf(_validOperators, operator) < 0
      throw new Error('Invalid operator: ', operator)
    if _.isUndefined(value)
      throw new Error('A value must be defined or null.')

    self.createOrUpdate('seats', {key: 'totalSeats', operator: operator, value: value, operator2: operator2, value2: value2})
    return
  trackSeats: () ->
    self = this
    Tracker.autorun ->
      obj = self.seats.get()
      if _.isNull(obj)
        return
      self.setSeats(obj.operator, obj.value, obj.operator2, obj.value2)
      async.nextTick(()->
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
        self.createOrUpdate('departure', {key: 'departureAirport._id', operator: '$in', value: code})
      else
        self.createOrUpdate('departure', {key: 'departureAirport._id', operator: '$in', value: [code]})
    else
      if _.isNull(code)
        Template.gritsSearchAndAdvancedFiltration.getDepartureSearch().tokenfield('setTokens', [])
        self.departures.set([])
        return
      if _.isEmpty(code)
        Template.gritsSearchAndAdvancedFiltration.getDepartureSearch().tokenfield('setTokens', [])
        self.departures.set([])
        return
      if _.isArray(code)
        Template.gritsSearchAndAdvancedFiltration.getDepartureSearch().tokenfield('setTokens', code)
        self.departures.set(code)
      else
        Template.gritsSearchAndAdvancedFiltration.getDepartureSearch().tokenfield('setTokens', [code])
        self.departures.set([code])
    return
  trackDepartures: () ->
    self = this
    Tracker.autorun ->
      obj = self.departures.get()
      self.setDepartures(obj)
      async.nextTick(()->
        self.compareStates()
      )
    return
  # sets the arrival input on the UI to the 'code'
  # specified, as well as, updating the underlying FilterCriteria.
  #
  # @param [String] code, an airport IATA code
  # @see http://www.iata.org/Pages/airports.aspx
  setArrivals: (code) ->
    self = this

    # do not allow this to run prior to jQuery/DOM
    if _.isUndefined($)
      return
    if _.isUndefined(code)
      throw new Error('A code must be defined or null.')

    if _.isEqual(self.arrivals.get(), code)
      # the call is from the UI
      if _.isNull(code)
        self.remove('arrival')
        return
      if _.isEmpty(code)
        self.remove('arrival')
        return
      if _.isArray(code)
         self.createOrUpdate('arrival', {key: 'arrivalAirport._id', operator: '$in', value: code})
      else
         self.createOrUpdate('arrival', {key: 'arrivalAirport._id', operator: '$in', value: [code]})
    else
      if _.isNull(code)
        Template.gritsSearchAndAdvancedFiltration.getArrivalSearch().tokenfield('setTokens', [])
        self.arrivals.set([])
        return
      if _.isEmpty(code)
        Template.gritsSearchAndAdvancedFiltration.getArrivalSearch().tokenfield('setTokens', [])
        self.arrivals.set([])
        return
      if _.isArray(code)
        Template.gritsSearchAndAdvancedFiltration.getArrivalSearch().tokenfield('setTokens', code)
        self.arrivals.set(code)
      else
        Template.gritsSearchAndAdvancedFiltration.getArrivalSearch().tokenfield('setTokens', [code])
        self.arrivals.set([code])
    return
  trackArrivals: () ->
    self = this
    Tracker.autorun ->
      obj = self.arrivals.get()
      self.setArrivals(obj)
      async.nextTick(()->
        self.compareStates()
      )
    return
  # sets the level input on the UI to the 'value'
  # specified, as well as, updating the underlying FilterCriteria.
  #
  # @note This is not part of the query, but is included to maintain the UI state.  Upon 'apply' the value is deleted from the query and used as an arguement to the server-side method
  # @param [Integer] value
  setLevels: (value) ->
    self = this

    # do not allow this to run prior to jQuery/DOM
    if _.isUndefined($)
      return

    if _.isUndefined(value)
      throw new Error('Level must be defined.')

    if _.isEqual(self.levels.get(), value)
      if _.isNull(value)
        self.remove('levels')
      else
        val = Math.floor(parseInt(value, 10))
        if isNaN(val) or val < 1
          throw new Error('Level must be positive')
        self.createOrUpdate('levels', {key: 'levels', operator: '$eq', value: val})
    else
      self.levels.set(value)
    return
  trackLevels: () ->
    self = this
    Tracker.autorun ->
      obj = self.levels.get()
      try
        self.setLevels(obj)
        async.nextTick(()->
          self.compareStates()
        )
      catch e
        Meteor.gritsUtil.errorHandler(e)
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
        async.nextTick(()->
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

    totalRecords = Session.get('grits-net-meteor:totalRecords')
    loadedRecords = Session.get('grits-net-meteor:loadedRecords')

    if (loadedRecords < totalRecords)
      self.offset.set(loadedRecords)
    else
      self.offset.set(0)
    self.more()
    return

GritsFilterCriteria = new GritsFilterCriteria() # exports as a singleton
