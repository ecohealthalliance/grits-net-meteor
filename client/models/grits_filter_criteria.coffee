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

## Public API
# GritsFilterCriteria
#
# This object provides the interface for interacting with the
# filter form inputs and maintaining the collection of filter criteria.
GritsFilterCriteria = {
  # createOrUpdate
  #
  # 
  createOrUpdate : (id, fields) ->
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
  # remove
  #
  #
  remove : (id, cb) ->
    obj = _Collection.findOne({_id: id})
    if obj and cb
      obj.remove(cb)
      return
    if obj
      return obj.remove()
    else
      return 0
  # getQueryObject
  #
  #
  getQueryObject : () ->
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
  # apply
  #
  #
  apply : () ->
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
  # setDayOfWeek
  #
  #
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
  # setWeeklyFrequency
  #
  #
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
  # setStops
  #
  #
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
  # setSeats
  #
  #
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
  # setDeparture
  #
  #
  setDeparture : (code) ->
    if _.isUndefined(code)
      throw new Error('A code must be defined or null.')
    if _.isNull(code)
      GritsFilterCriteria.remove('departure')
      Template.gritsFilter.departureSearch.tokenfield('setTokens', [])
      return  
    if _.isArray(code)
      GritsFilterCriteria.createOrUpdate('departure', {key: 'departureAirport._id', operator: '$in', value: code})
      Template.gritsFilter.departureSearch.tokenfield('setTokens', code)
    else
      GritsFilterCriteria.createOrUpdate('departure', {key: 'departureAirport._id', operator: '$in', value: [code]})
      Template.gritsFilter.departureSearch.tokenfield('setTokens', [code])
    return
  # setArrival
  #
  #
  setArrival : (code) ->
    if _.isUndefined(code)
      throw new Error('A code must be defined or null.')
    if _.isNull(code)
      GritsFilterCriteria.remove('arrival')
      Template.gritsFilter.departureSearch.tokenfield('setTokens', [])
      return  
    if _.isArray(code)
      GritsFilterCriteria.createOrUpdate('arrival', {key: 'arrivalAirport._id', operator: '$in', value: code})
      Template.gritsFilter.departureSearch.tokenfield('setTokens', code)
    else
      GritsFilterCriteria.createOrUpdate('arrival', {key: 'arrivalAirport._id', operator: '$in', value: [code]})
      Template.gritsFilter.departureSearch.tokenfield('setTokens', [code])
    return
  # setLevels
  #
  #
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
  # setLimit
  #
  #
  setLimit : (value) ->
    if _.isUndefined(value)
      throw new Error('A value must be defined or null.')
    val = Math.floor(parseInt(value, 10))
    if isNaN(val) or val < 1
      throw new Error('Limit must be positive')    
    $('#limit').val(val)
    Session.set('grits-net-meteor:limit', val)
    return
  # scanAll
  #
  #
  scanAll : () ->
    for name, method of @scan
      method()
  # scan
  #
  #
  scan : {
    # scan.levels
    #
    #
    levels : () ->  
      val = $("#connectednessLevels").val()
      GritsFilterCriteria.remove('levels')
      if val isnt '' and val isnt '0'
        GritsFilterCriteria.createOrUpdate('levels', {key: 'flightNumber', operator:'$ne', value:-val})
    # scan.seats
    #
    # apply a filter on number of seats if it is not undefined or NaN
    seats : () ->
      val = parseInt($("#seatsInput").val())
      op = $('#seats-operand').val();
      if _.isUndefined(op)
        return
      if _.isUndefined(val) or isNaN(val)
        GritsFilterCriteria.remove('seats')
      else
        GritsFilterCriteria.createOrUpdate('seats', {key: 'totalSeats', operator: op, value: val})
    # scan.stops
    #
    # apply a filter on number of stops if it is not undefined or NaN
    stops : () ->
      val = parseInt($("#stopsInput").val())
      op = $('#stops-operand').val();
      if _.isUndefined(op)
        return
      if _.isUndefined(val) or isNaN(val)
        GritsFilterCriteria.remove('stops')
      else
        GritsFilterCriteria.createOrUpdate('stops', {key: 'stops', operator: op, value: val})
    # scan.departure
    #
    # apply a filter on the parsed airport codes from the departureSearch input
    # @param [String] str, the airport code
    departure : () ->
      combined = []
        
      if typeof Template.gritsFilter.departureSearchMain != 'undefined'
        tokens =  Template.gritsFilter.departureSearchMain.tokenfield('getTokens')
        codes = _.pluck(tokens, 'label')
        combined = _.union(codes, combined)
        
      if typeof Template.gritsFilter.departureSearch != 'undefined'
        tokens =  Template.gritsFilter.departureSearch.tokenfield('getTokens')
        codes = _.pluck(tokens, 'label')
        combined = _.union(codes, combined)
          
      if _.isEmpty(combined)
        GritsFilterCriteria.remove('departure')
      else
        GritsFilterCriteria.createOrUpdate('departure', {key: 'departureAirport._id', operator: '$in', value: combined})
    # scan.arrival
    #
    # apply a filter on the parsed airport codes from the arrivalSearch input
    # @param [String] str, the airport code
    arrival : () ->
      if typeof Template.gritsFilter.departureSearch != 'undefined'
        tokens =  Template.gritsFilter.arrivalSearch.tokenfield('getTokens')
        codes = _.pluck(tokens, 'label')
      if _.isEmpty(codes)
        GritsFilterCriteria.remove('arrival')
      else
        GritsFilterCriteria.createOrUpdate('arrival', {key: 'arrivalAirport._id', operator: '$in', value: codes})
    # scan.daysOfWeek
    #
    #
    daysOfWeek : () ->
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
    # scan.weeklyFrequency
    #
    #
    weeklyFrequency : () ->
      val = parseInt($("#weeklyFrequencyInput").val())
      op = $('#weekly-frequency-operand').val();
      if _.isUndefined(op)
        return
      if _.isUndefined(val) or isNaN(val)
        GritsFilterCriteria.remove('weeklyFrequency')
      else
        GritsFilterCriteria.createOrUpdate('weeklyFrequency', {key: 'weeklyFrequency', operator: op, value: val})
  }
}