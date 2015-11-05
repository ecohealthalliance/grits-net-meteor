extendQuery = (query, lastId) ->
  # all flights are filtered by current date being past the discontinuedDate
  # or before the effectiveDate
  now = new Date()
  activeFilter =
    $and: [
      effectiveDate: {$lt: now}, # effectiveDate is less than now
      discontinuedDate: {$gte: now} # discontinuedDate is greater-equal than now
    ]
  _.extend query, activeFilter
  # offset
  if !(_.isUndefined(lastId) or _.isNull(lastId))
    offsetFilter = _id: $gt: lastId
    _.extend query, offsetFilter

buildOptions = (limit) ->
  options =
    sort:
      _id: 1
      #effectiveDate: -1

  # limit
  if !(_.isUndefined(limit) or _.isNull(limit))
    limitClause =
      limit: limit
    _.extend options, limitClause
  return options

Meteor.publish 'flightsByQuery', (query, limit, lastId) ->
  if _.isUndefined(query) or _.isEmpty(query)
    return []

  extendQuery(query, lastId)
  options = buildOptions(limit)

  console.log 'query: ', query
  console.log 'options: ', options

  return Flights.find(query, options);

Meteor.methods
  countFlightsByQuery: (query) ->
    if _.isUndefined(query) or _.isEmpty(query)
      return 0

    extendQuery(query, null)
    buildOptions(null)

    return Flights.find(query).count()

Meteor.methods
  getFlightsByLevel: (query, levels, origin) ->
    if _.isUndefined(query) or _.isEmpty(query)
      return 'query is empty'
    if levels < 2
      return 'levels is less than two: ' + levels
    extendQuery(query, null)
    buildOptions(null)
    ctr = 1
    origins = []
    for o of origin
      origins.push(origin[o])    
    console.log 'original origins:' , origins
    flights = null
    while ctr < levels
      flights = Flights.find(query).fetch()
      for flight of flights
        origins.push(flights[flight].arrivalAirport._id)
      ctr++
      query['departureAirport._id'] = {'$in':origins}
    console.log 'level query: ', query
    return Flights.find(query).fetch()

Meteor.publish 'autoCompleteAirports', (query, options) ->
  Autocomplete.publishCursor(Airports.find(query, options), this)
  this.ready()
