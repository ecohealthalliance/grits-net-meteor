_validFields = ['weeklyFrequency', 'stops', 'seats', 'departure', 'arrival', 'levels', 'effectiveDate', 'discontinuedDate']
_validOperators = ['$gte', '$gt', '$lte', '$lt', '$eq', '$ne', '$in', '$near']
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
# accessing the UI filter box.
# @note exports as a 'singleton'
class GritsFilterCriteria
  constructor: () ->
    self = this
    # reactive var used to update the UI when the query state has changed
    self.stateChanged = new ReactiveVar(null)
    # reactive var used to track the departures
    self.departures = new ReactiveVar(null)    
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
    return "#{month}/#{date}/#{year}"
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
    year = end.getFullYear().toString().slice(2,4)
    return "#{month}/#{date}/#{year}"
  # Creates a new filter criteria and adds it to the collection or updates
  # the collection if it already exists
  #
  # @param [String] id, the name of the filter criteria
  # @note must be one of 'day1', 'day2', 'day3', 'day4', 'day5', 'day6',
  #   'day7', 'weeklyFrequency', 'stops', 'seats', 'departure', 'arrival',
  #   'levels'
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
  # @note must be one of 'day1', 'day2', 'day3', 'day4', 'day5', 'day6',
  #   'day7', 'weeklyFrequency', 'stops', 'seats', 'departure', 'arrival',
  #   'levels'
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
    # timeout to avoid 'flash' affect for those who quickly change the UI
    setTimeout(() ->
      current = self.getCurrentState()
      if current != _state
        # do not notifiy on an empty query or the base state
        if current == "{}" || current == self._baseState
          self.stateChanged.set(false)  
        else
          self.stateChanged.set(true)
      else
        self.stateChanged.set(false)
    , 500)
  # gets the current state of the filter
  #
  # @return [String] the query object JSON.strigify
  getCurrentState: () ->
    self = this
    self.scanAll()
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
    self.scanAll()
    query = self.getQueryObject()
    _state = JSON.stringify(query)
    return
  # applies the filter directly, without using the global session 'query' object
  # and allows binding an anonymous function to be called at the end of the
  # asynchronous comunication with the server
  #
  # @param [Function] cb, the callback function
  applyWithCallback: (cb) ->
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

    # re-enable the loadMore button when a new filter is applied
    $('#loadMore').prop('disabled', false)
    limit = parseInt($('#limit').val(), 10)

    Session.set('grits-net-meteor:isUpdating', true)
    Meteor.call('flightsByQuery', query, limit, null, (err, flights) ->
      if (err)
        Meteor.gritsUtil.errorHandler(err)
        return

      if _.isUndefined(flights) || _.isEmpty(flights)
        Session.set('grits-net-meteor:isUpdating', false)
        toastr.info('No data was returned')
        return

      Meteor.call 'countFlightsByQuery', query, (err, totalRecords) ->
        if (err)
          Meteor.gritsUtil.errorHandler(err)
          return

        Session.set 'grits-net-meteor:totalRecords', totalRecords
        Meteor.gritsUtil.process(flights, limit, null)

        if cb && _.isFunction(cb)
          cb(null, flights)
      return
    )
    return
  # sets the global Session 'grits-net-meteor:query' object to the current
  # getQueryObject.  This will trigger an update of the map through the
  # server-side publication
  apply: () ->
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

    # re-enable the loadMore button when a new filter is applied
    $('#loadMore').prop('disabled', false)

    limit = parseInt($('#limit').val(), 10)
    if !_.isNaN(limit)
      Session.set 'grits-net-meteor:limit', limit
    else
      Session.set 'grits-net-meteor:limit', null
    Session.set 'grits-net-meteor:lastId', null
    Session.set 'grits-net-meteor:query', query
    return
  # sets the 'start' date from the filter and updates the filter criteria
  setOperatingDateRangeStart: (date) ->
    self = this
    discontinuedDatePicker = Template.gritsFilter.getDiscontinuedDatePicker()
    if _.isNull(discontinuedDatePicker)
      return
    discontinuedDate = discontinuedDatePicker.data('DateTimePicker').date(date)
    self.createOrUpdate('discontinuedDate', {key: 'discontinuedDate', operator: '$gte', value: discontinuedDate})
    return
  # reads the 'end' date from the filter and updates the filter criteria
  setOperatingDateRangeEnd: (date) ->
    self = this
    effectiveDatePicker = Template.gritsFilter.getEffectiveDatePicker()
    if _.isNull(effectiveDatePicker)
      return
    effectiveDate = effectiveDatePicker.data('DateTimePicker').date(date)
    self.createOrUpdate('effectiveDate', {key: 'effectiveDate', operator: '$lte', value: effectiveDate})
    return
  # sets the weeklyFrequency input on the UI to the 'operator' and 'value'
  # specified, as well as, updating the underlying FilterCriteria.
  #
  # @param [String] operator, one of '$gte', '$gt', '$lte', '$lt', '$eq', '$ne', '$in'
  # @param [Integer] value
  setWeeklyFrequency: (operator, value) ->
    self = this
    if _.indexOf(_validOperators, operator) < 0
      throw new Error('Invalid operator: ', operator)
    if _.isUndefined(value)
      throw new Error('A value must be defined or null.')

    if _.isNull(value)
      self.remove('weeklyFrequency')
    else
      self.createOrUpdate('weeklyFrequency', {key: 'weeklyFrequency', operator: operator, value: value})

    $('#weekly-frequency-operand').val(operator)
    $("#weeklyFrequencyInput").val(value)
    return
  # sets the stops input on the UI to the 'operator' and 'value'
  # specified, as well as, updating the underlying FilterCriteria.
  #
  # @param [String] operator, one of '$gte', '$gt', '$lte', '$lt', '$eq', '$ne', '$in'
  # @param [Integer] value
  setStops: (operator, value) ->
    self = this
    if _.indexOf(_validOperators, operator) < 0
      throw new Error('Invalid operator: ', operator)
    if _.isUndefined(value)
      throw new Error('A value must be defined or null.')

    if _.isNull(value)
      self.remove('stops')
    else
      self.createOrUpdate('stops', {key: 'stops', operator: operator, value: value})

    $('#stops-operand').val(operator)
    $("#stopsInput").val(value)
    return
  # sets the seats input on the UI to the 'operator' and 'value'
  # specified, as well as, updating the underlying FilterCriteria.
  #
  # @param [String] operator, one of '$gte', '$gt', '$lte', '$lt', '$eq', '$ne', '$in'
  # @param [Integer] value
  setSeats: (operator, value) ->
    self = this
    if _.indexOf(_validOperators, operator) < 0
      throw new Error('Invalid operator: ', operator)
    if _.isUndefined(value)
      throw new Error('A value must be defined or null.')

    if _.isNull(value)
      self.remove('seats')
    else
      self.createOrUpdate('seats', {key: 'totalSeats', operator: operator, value: value})

    $('#seats-operand').val(operator)
    $("#seatsInput").val(value)
    return
  # sets the departure input on the UI to the 'code'
  # specified, as well as, updating the underlying FilterCriteria.
  #
  # @param [String] code, an airport IATA code
  # @see http://www.iata.org/Pages/airports.aspx
  setDeparture: (code) ->
    self = this
    if _.isUndefined(code)
      throw new Error('A code must be defined or null.')
    if _.isNull(code)
      self.remove('departure')
      Template.gritsFilter.getDepartureSearch().tokenfield('setTokens', [])
      self.departures.set(null)
      return
    if _.isEmpty(code)
      self.remove('departure')
      Template.gritsFilter.getDepartureSearch().tokenfield('setTokens', [])
      self.departures.set(null)
      return
    if _.isArray(code)
      self.createOrUpdate('departure', {key: 'departureAirport._id', operator: '$in', value: code})
      Template.gritsFilter.getDepartureSearch().tokenfield('setTokens', code)
      @departures.set(code)
    else
      self.createOrUpdate('departure', {key: 'departureAirport._id', operator: '$in', value: [code]})
      Template.gritsFilter.getDepartureSearch().tokenfield('setTokens', [code])
      self.departures.set([code])
    return
  # sets the arrival input on the UI to the 'code'
  # specified, as well as, updating the underlying FilterCriteria.
  #
  # @param [String] code, an airport IATA code
  # @see http://www.iata.org/Pages/airports.aspx
  setArrival: (code) ->
    self = this
    if _.isUndefined(code)
      throw new Error('A code must be defined or null.')
    if _.isNull(code)
      self.remove('arrival')
      Template.gritsFilter.getArrivalSearch().tokenfield('setTokens', [])
      return
    if _.isArray(code)
      self.createOrUpdate('arrival', {key: 'arrivalAirport._id', operator: '$in', value: code})
      Template.gritsFilter.getArrivalSearch().tokenfield('setTokens', code)
    else
      self.createOrUpdate('arrival', {key: 'arrivalAirport._id', operator: '$in', value: [code]})
      Template.gritsFilter.getArrivalSearch().tokenfield('setTokens', [code])
    return
  # sets the level input on the UI to the 'value'
  # specified, as well as, updating the underlying FilterCriteria.
  #
  # @param [Intever] value
  setLevels: (value) ->
    self = this
    if _.isUndefined(value)
      throw new Error('A value must be defined or null.')
    if _.isNull(value)
      Session.set('grits-net-meteor:levels', null)
      return
    val = Math.floor(parseInt(value, 10))
    if isNaN(val) or val < 1
      throw new Error('Level must be positive')
    Session.set('grits-net-meteor:levels', val)
    $("#connectednessLevels").val(val)
    return
  # sets the limit input on the UI to the 'value'
  # specified, as well as, updating the underlying global Session
  # 'grits-net-meteor:limit' variable.
  #
  # @param [Intever] value
  setLimit: (value) ->
    self = this
    if _.isUndefined(value)
      throw new Error('A value must be defined or null.')
    val = Math.floor(parseInt(value, 10))
    if isNaN(val) or val < 1
      throw new Error('Limit must be positive')
    $('#limit').val(val)
    Session.set('grits-net-meteor:limit', val)
    return
  # convenience method for reading all the filter UI inputs and creating and/or
  # updating the underlying FilterCriteria
  scanAll: () ->
    self = this
    for name, method of self
      if name.indexOf('read') >= 0
        self[name]()
    return
  # reads the 'start' date from the filter and updates the filter criteria
  readOperatingDateRangeStart: () ->
    self = this
    discontinuedDatePicker = Template.gritsFilter.getDiscontinuedDatePicker()
    if _.isNull(discontinuedDatePicker)
      return
    discontinuedDate = discontinuedDatePicker.data('DateTimePicker').date()
    if _.isUndefined(discontinuedDate) || _.isEmpty(discontinuedDate)
      self.remove('discontinuedDate')
      return
    self.createOrUpdate('discontinuedDate', {key: 'discontinuedDate', operator: '$gte', value: discontinuedDate})
    return
  # reads the 'end' date from the filter and updates the filter criteria
  readOperatingDateRangeEnd: () ->
    self = this
    effectiveDatePicker = Template.gritsFilter.getEffectiveDatePicker()
    if _.isNull(effectiveDatePicker)
      return
    effectiveDate = effectiveDatePicker.data('DateTimePicker').date()
    if _.isUndefined(effectiveDate) || _.isEmpty(effectiveDate)
      self.remove('effectiveDate')
      return
    self.createOrUpdate('effectiveDate', {key: 'effectiveDate', operator: '$lte', value: effectiveDate})
    return
  # reads the 'levels' input currently displayed on the filter UI
  # then calls the setter to set the Session variable
  # @note: we do not add to the underlying FilterCriteria
  readLevels: () ->
    self = this
    val = $("#connectednessLevels").val()
    try
      self.setLevels(val)
    catch e
      console.error(e)
    return
  readIncludeNearbyAirports: () ->
    self = this
    miles = $("#includeNearbyAirportsRadius").val()
    if $('#includeNearbyAirports').is(':checked')
      departures = self.readDeparture()
      if departures.length >= 0
        Meteor.call('findAirportById', departures[0], (err, airport) ->
          #self.setIncludeNearbyAirports(true, miles, airport.loc.coordinates)
        )
    return
  # reads the 'seats' input currently displayed on the filter UI,
  # then creates and/or updates the underlying FilterCriteria
  readSeats: () ->
    self = this
    val = parseInt($("#seatsInput").val())
    op = $('#seats-operand').val()
    if _.isUndefined(op)
      return
    if _.isUndefined(val) or isNaN(val)
      self.remove('seats')
    else
      self.createOrUpdate('seats', {key: 'totalSeats', operator: op, value: val})
    return
  # reads the 'stops' input currently displayed on the filter UI,
  # then creates and/or updates the underlying FilterCriteria
  readStops: () ->
    self = this
    val = parseInt($("#stopsInput").val())
    op = $('#stops-operand').val()
    if _.isUndefined(op)
      return
    if _.isUndefined(val) or isNaN(val)
      @remove('stops')
    else
      @createOrUpdate('stops', {key: 'stops', operator: op, value: val})
    return
  # reads the 'departure' input currently displayed on the filter UI,
  # then creates and/or updates the underlying FilterCriteria
  #
  # @return [Array] combined, departures from #departureSearchMain and #departureSearch inputs
  readDeparture: () ->
    self = this
    combined = []

    if typeof Template.gritsFilter.getDepartureSearchMain() != 'undefined'
      tokens =  Template.gritsFilter.getDepartureSearchMain().tokenfield('getTokens')
      codes = _.pluck(tokens, 'label')
      combined = _.union(codes, combined)

    if typeof Template.gritsFilter.getDepartureSearch() != 'undefined'
      tokens =  Template.gritsFilter.getDepartureSearch().tokenfield('getTokens')
      codes = _.pluck(tokens, 'label')
      combined = _.union(codes, combined)

    if _.isEqual(combined, self.departures.get())
      return combined
    else
      self.setDeparture(combined)
      return combined
  # reads the 'arrival' input currently displayed on the filter UI,
  # then creates and/or updates the underlying FilterCriteria
  readArrival: () ->
    self = this
    if typeof Template.gritsFilter.getDepartureSearch() != 'undefined'
      tokens =  Template.gritsFilter.getArrivalSearch().tokenfield('getTokens')
      codes = _.pluck(tokens, 'label')
    if _.isEmpty(codes)
      self.remove('arrival')
    else
      self.createOrUpdate('arrival', {key: 'arrivalAirport._id', operator: '$in', value: codes})
    return
  # reads the 'weeklyFrequency' input currently displayed on the filter UI,
  # then creates and/or updates the underlying FilterCriteria
  readWeeklyFrequency: () ->
    self = this
    val = parseInt($("#weeklyFrequencyInput").val())
    op = $('#weekly-frequency-operand').val()
    if _.isUndefined(op)
        return
    if _.isUndefined(val) or isNaN(val)
      self.remove('weeklyFrequency')
    else
      self.createOrUpdate('weeklyFrequency', {key: 'weeklyFrequency', operator: op, value: val})
    return

GritsFilterCriteria = new GritsFilterCriteria() # exports as a singleton
