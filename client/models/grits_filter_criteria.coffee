_validFields = ['day1', 'day2', 'day3', 'day4', 'day5', 'day6', 'day7', 'weeklyFrequency', 'stops', 'seats', 'departure', 'arrival', 'levels']
_validDays = ['SUN','MON','TUE','WED','THU','FRI','SAT']
_validOperators = ['$gte', '$gt', '$lte', '$lt', '$eq', '$ne', '$in']
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
class FilterCriteria
  # Creates a new filter criteria and adds it to the collection or updates
  # the collection if it already exists
  #
  # @param [String] id, the name of the filter criteria
  # @note must be one of 'day1', 'day2', 'day3', 'day4', 'day5', 'day6',
  #   'day7', 'weeklyFrequency', 'stops', 'seats', 'departure', 'arrival',
  #   'levels'
  # @return [Object] Astronomy model 'FilterCriteria'
  createOrUpdate: (id, fields) ->
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
    criteria = _Collection.find({})
    result = {}
    criteria.forEach((filter) ->
      value = {}
      o = filter.get('operator')
      v = filter.get('value')
      if _.indexOf(['$eq'], o) >= 0
        value = v
      else
        value[o] = v
      result[filter.get('key')] = value
    )
    return result
  
  # sets the global Session 'grits-net-meteor:query' object to the current
  # getQueryObject.  This will trigger an update of the map through the
  # server-side publication
  apply: () ->
    query = GritsFilterCriteria.getQueryObject()
    if _.isUndefined(query) or _.isEmpty(query)
      return
  
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
  
  # sets the corresponding checkbox on the UI to the 'day' and 'value'
  # specified, as well as, updating the underlying FilterCriteria.
  #
  # @param [String] day, one of 'SUN','MON','TUE','WED','THU','FRI','SAT'
  # @param [Boolean] value, true or false
  setDayOfWeek : (day, value) ->
    if _.indexOf(_validDays, day.toUpperCase()) < 0
      throw new Error('Invalid day: ' + day)
    setField = (field) ->
      if value
        $('#dow'+day).prop('checked', true)     
        GritsFilterCriteria.createOrUpdate(field, {key: field, operator: '$eq', 'value': true})
      else
        $('#dow'+day).prop('checked', false)
        GritsFilterCriteria.remove(field)
    if day == 'SUN'
      setField('day1')
    else if day == 'MON'
      setField('day2')
    else if day == 'TUE'
      setField('day3')
    else if day == 'WED'
      setField('day4')
    else if day == 'THU'
      setField('day5')
    else if day == 'FRI'
      setField('day6')
    else if day == 'SAT'
      setField('day7')
    return
  
  # sets the weeklyFrequency input on the UI to the 'operator' and 'value'
  # specified, as well as, updating the underlying FilterCriteria.
  #
  # @param [String] operator, one of '$gte', '$gt', '$lte', '$lt', '$eq', '$ne', '$in'
  # @param [Integer] value
  setWeeklyFrequency : (operator, value) ->
    if _.indexOf(_validOperators, operator) < 0
      throw new Error('Invalid operator: ', operator)
    if _.isUndefined(value)
      throw new Error('A value must be defined or null.')
    
    if _.isNull(value)
      GritsFilterCriteria.remove('weeklyFrequency')
    else
      GritsFilterCriteria.createOrUpdate('weeklyFrequency', {key: 'weeklyFrequency', operator: operator, value: value})
      
    $('#weekly-frequency-operand').val(operator);  
    $("#weeklyFrequencyInput").val(value);
    return
  
  # sets the stops input on the UI to the 'operator' and 'value'
  # specified, as well as, updating the underlying FilterCriteria.
  #
  # @param [String] operator, one of '$gte', '$gt', '$lte', '$lt', '$eq', '$ne', '$in'
  # @param [Integer] value
  setStops : (operator, value) ->
    if _.indexOf(_validOperators, operator) < 0
      throw new Error('Invalid operator: ', operator)
    if _.isUndefined(value)
      throw new Error('A value must be defined or null.')
    
    if _.isNull(value)
      GritsFilterCriteria.remove('stops')
    else
      GritsFilterCriteria.createOrUpdate('stops', {key: 'stops', operator: operator, value: value})
      
    $('#stops-operand').val(operator);  
    $("#stopsInput").val(value);
    return
  
  # sets the seats input on the UI to the 'operator' and 'value'
  # specified, as well as, updating the underlying FilterCriteria.
  #
  # @param [String] operator, one of '$gte', '$gt', '$lte', '$lt', '$eq', '$ne', '$in'
  # @param [Integer] value
  setSeats : (operator, value) ->
    if _.indexOf(_validOperators, operator) < 0
      throw new Error('Invalid operator: ', operator)
    if _.isUndefined(value)
      throw new Error('A value must be defined or null.')
    
    if _.isNull(value)
      GritsFilterCriteria.remove('seats')
    else
      GritsFilterCriteria.createOrUpdate('seats', {key: 'totalSeats', operator: operator, value: value})
      
    $('#seats-operand').val(operator);  
    $("#seatsInput").val(value);
    return
  
  # sets the departure input on the UI to the 'code'
  # specified, as well as, updating the underlying FilterCriteria.
  #
  # @param [String] code, an airport IATA code
  # @see http://www.iata.org/Pages/airports.aspx 
  setDeparture : (code) ->
    if _.isUndefined(code)
      throw new Error('A code must be defined or null.')
    if _.isNull(code)
      GritsFilterCriteria.remove('departure')
      Template.gritsFilter.getDepartureSearch().tokenfield('setTokens', [])
      return  
    if _.isArray(code)
      GritsFilterCriteria.createOrUpdate('departure', {key: 'departureAirport._id', operator: '$in', value: code})
      Template.gritsFilter.getDepartureSearch().tokenfield('setTokens', code)
    else
      GritsFilterCriteria.createOrUpdate('departure', {key: 'departureAirport._id', operator: '$in', value: [code]})
      Template.gritsFilter.getDepartureSearch().tokenfield('setTokens', [code])
    return
  
  # sets the arrival input on the UI to the 'code'
  # specified, as well as, updating the underlying FilterCriteria.
  #
  # @param [String] code, an airport IATA code
  # @see http://www.iata.org/Pages/airports.aspx 
  setArrival : (code) ->
    if _.isUndefined(code)
      throw new Error('A code must be defined or null.')
    if _.isNull(code)
      GritsFilterCriteria.remove('arrival')
      Template.gritsFilter.getArrivalSearch().tokenfield('setTokens', [])
      return  
    if _.isArray(code)
      GritsFilterCriteria.createOrUpdate('arrival', {key: 'arrivalAirport._id', operator: '$in', value: code})
      Template.gritsFilter.getArrivalSearch().tokenfield('setTokens', code)
    else
      GritsFilterCriteria.createOrUpdate('arrival', {key: 'arrivalAirport._id', operator: '$in', value: [code]})
      Template.gritsFilter.getArrivalSearch().tokenfield('setTokens', [code])
    return
  
  # sets the level input on the UI to the 'value'
  # specified, as well as, updating the underlying FilterCriteria.
  #
  # @param [Intever] value
  setLevels : (value) ->
    if _.isUndefined(value)
      throw new Error('A value must be defined or null.')
    if _.isNull(value)
      GritsFilterCriteria.remove('levels')
      $("#connectednessLevels").val(null)
      return
    val = Math.floor(parseInt(value, 10))
    if isNaN(val) or val < 1
      throw new Error('Level must be positive')    
    GritsFilterCriteria.createOrUpdate('levels', {key: 'flightNumber', operator: '$ne', value: -val})
    $("#connectednessLevels").val(val)
    return
  
  # sets the limit input on the UI to the 'value'
  # specified, as well as, updating the underlying global Session
  # 'grits-net-meteor:limit' variable.
  #
  # @param [Intever] value
  setLimit : (value) ->
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
  scanAll : () ->
    for name, method of this
      if name.indexOf('read') >= 0
        method()
    return
  
  # scans (reads) the 'levels' input currently displayed on the filter UI,
  # then creates and/or updates the underlying FilterCriteria
  readLevels : () ->
    val = $("#connectednessLevels").val()
    GritsFilterCriteria.remove('levels')
    if val isnt '' and val isnt '0'
      GritsFilterCriteria.createOrUpdate('levels', {key: 'flightNumber', operator:'$ne', value:-val})
    return
  
  # scans (reads) the 'seats' input currently displayed on the filter UI,
  # then creates and/or updates the underlying FilterCriteria
  readSeats : () ->
    val = parseInt($("#seatsInput").val())
    op = $('#seats-operand').val();
    if _.isUndefined(op)
      return
    if _.isUndefined(val) or isNaN(val)
      GritsFilterCriteria.remove('seats')
    else
      GritsFilterCriteria.createOrUpdate('seats', {key: 'totalSeats', operator: op, value: val})
    return
  
  # scans (reads) the 'stops' input currently displayed on the filter UI,
  # then creates and/or updates the underlying FilterCriteria
  readStops : () ->
    val = parseInt($("#stopsInput").val())
    op = $('#stops-operand').val();
    if _.isUndefined(op)
      return
    if _.isUndefined(val) or isNaN(val)
      GritsFilterCriteria.remove('stops')
    else
      GritsFilterCriteria.createOrUpdate('stops', {key: 'stops', operator: op, value: val})
    return
  
  # scans (reads) the 'departure' input currently displayed on the filter UI,
  # then creates and/or updates the underlying FilterCriteria
  readDeparture : () ->
    combined = []
      
    if typeof Template.gritsFilter.getDepartureSearchMain() != 'undefined'
      tokens =  Template.gritsFilter.getDepartureSearchMain().tokenfield('getTokens')
      codes = _.pluck(tokens, 'label')
      combined = _.union(codes, combined)
      
    if typeof Template.gritsFilter.getDepartureSearch() != 'undefined'
      tokens =  Template.gritsFilter.getDepartureSearch().tokenfield('getTokens')
      codes = _.pluck(tokens, 'label')
      combined = _.union(codes, combined)
        
    if _.isEmpty(combined)
      GritsFilterCriteria.remove('departure')
    else
      GritsFilterCriteria.createOrUpdate('departure', {key: 'departureAirport._id', operator: '$in', value: combined})
  
  # scans (reads) the 'arrival' input currently displayed on the filter UI,
  # then creates and/or updates the underlying FilterCriteria
  readArrival : () ->
    if typeof Template.gritsFilter.getDepartureSearch() != 'undefined'
      tokens =  Template.gritsFilter.getArrivalSearch().tokenfield('getTokens')
      codes = _.pluck(tokens, 'label')
    if _.isEmpty(codes)
      GritsFilterCriteria.remove('arrival')
    else
      GritsFilterCriteria.createOrUpdate('arrival', {key: 'arrivalAirport._id', operator: '$in', value: codes})
    return
  
  # scans (reads) the 'days Of Week' checkboxes currently displayed on the
  # filter UI, then creates and/or updates the underlying FilterCriteria
  readDaysOfWeek : () ->
    day = 'day1'
    if $('#dowSUN').is(':checked')      
      GritsFilterCriteria.createOrUpdate(day, {key: day, operator: '$eq', 'value': true})
    else if !$('#dowSUN').is(':checked')
      GritsFilterCriteria.remove(day)
     
    day = 'day2'
    if $('#dowMON').is(':checked')
      GritsFilterCriteria.createOrUpdate(day, {key: day, operator: '$eq', 'value': true})
    else if !$('#dowMON').is(':checked')
      GritsFilterCriteria.remove(day)
  
    day = 'day3'
    if $('#dowTUE').is(':checked')
      GritsFilterCriteria.createOrUpdate(day, {key: day, operator: '$eq', 'value': true})
    else if !$('#dowTUE').is(':checked')
      GritsFilterCriteria.remove(day)
  
    day = 'day4'
    if $('#dowWED').is(':checked')
      GritsFilterCriteria.createOrUpdate(day, {key: day, operator: '$eq', 'value': true})
    else if !$('#dowWED').is(':checked')
      GritsFilterCriteria.remove(day)
  
    day = 'day5'
    if $('#dowTHU').is(':checked')
      GritsFilterCriteria.createOrUpdate(day, {key: day, operator: '$eq', 'value': true})
    else if !$('#dowTHU').is(':checked')
      GritsFilterCriteria.remove(day)
  
    day = 'day6'
    if $('#dowFRI').is(':checked')
      GritsFilterCriteria.createOrUpdate(day, {key: day, operator: '$eq', 'value': true})
    else if !$('#dowFRI').is(':checked')
      GritsFilterCriteria.remove(day)
  
    day = 'day7'
    if $('#dowSAT').is(':checked')
      GritsFilterCriteria.createOrUpdate(day, {key: day, operator: '$eq', 'value': true})
    else if !$('#dowSAT').is(':checked')
      GritsFilterCriteria.remove(day)
    return
  
  # scans (reads) the 'weeklyFrequency' input currently displayed on the filter UI,
  # then creates and/or updates the underlying FilterCriteria
  readWeeklyFrequency : () ->
      val = parseInt($("#weeklyFrequencyInput").val())
      op = $('#weekly-frequency-operand').val();
      if _.isUndefined(op)
        return
      if _.isUndefined(val) or isNaN(val)
        GritsFilterCriteria.remove('weeklyFrequency')
      else
        GritsFilterCriteria.createOrUpdate('weeklyFrequency', {key: 'weeklyFrequency', operator: op, value: val})
      return
  
GritsFilterCriteria = new FilterCriteria() #GritsFilterCriteria exports as a singleton