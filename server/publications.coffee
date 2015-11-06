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
  getFlightsByLevel: (query, levels, origin, limit) ->
    if _.isUndefined(query) or _.isEmpty(query)
      return 'query is empty'
    if levels < 2
      return 'levels is less than two: ' + levels
    extendQuery(query, null)
    ctr = 1
    flightsByLevel = []
    originsByLevel = []
    originsByLevel[1] = origin
    while ctr < levels
      flights = Flights.find(query).fetch()
      flightsByLevel[ctr] = flights
      originsByLevel[ctr+1] = []
      for flight of flights
        originsByLevel[ctr+1].push(flights[flight].arrivalAirport._id)
      query['departureAirport._id'] = {'$in':originsByLevel[ctr+1]}
      ctr++
    retFlightCount = 0
    retFlightByLevIndex = 0
    for flights of flightsByLevel
      console.log "flights: ", flights
      if flightsByLevel[flights].length <= (limit - retFlightCount)
        retFlightCount += flightsByLevel[flights].length
        retFlightByLevIndex++
        continue
      else
        break
    if limit isnt null
      limit = limit - retFlightCount
    options = buildOptions(limit)
    flightsToReturn = []
    for flights of flightsByLevel
      if flights <= retFlightByLevIndex
        Array::push.apply flightsToReturn, flightsByLevel[flights]
    # combine
    originArray = []
    for origins of originsByLevel
      Array::push.apply originArray, originsByLevel[origins]
    console.log 'originArray:', originArray
    query['departureAirport._id'] = {'$in':originArray}
    totalCount = Flights.find(query).fetch().length
    if limit isnt null
      query['departureAirport._id'] = {'$in':originsByLevel[retFlightByLevIndex+1]}
    if retFlightByLevIndex > 0
      trailingFlights = Flights.find(query, options).fetch()
    else
      trailingFlights = Flights.find(query, options).fetch()
    Array::push.apply flightsToReturn, trailingFlights
    return [flightsToReturn, totalCount]

Meteor.publish 'autoCompleteAirports', (query, options) ->
  Autocomplete.publishCursor(Airports.find(query, options), this)
  this.ready()
