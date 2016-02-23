Future = Npm.require('fibers/future');

_FLIRT_SIMULATOR_URL = process.env.FLIRT_SIMULATOR_URL
if _FLIRT_SIMULATOR_URL == ''
  throw new Error('You must set FLIRT_SIMULATOR_URL environment variable, ex: http://localhost:45000/simulator');

_useAggregation = true # enable/disable using the aggregation framework
_profile = false # enable/disable recording method performance to the collection 'profiling'
_activeAirports = null
# collection to record profiling results
Profiling = new Mongo.Collection('profiling')
# records a profile document to mongo when profiling is enabled
#
# @param [String] methodName, the name of the method that is being profiled
# @param [Integer] elsapsedTime, the elapsed time in milliseconds
recordProfile = (methodName, elapsedTime) ->
  Profiling.insert({methodName: methodName, elapsedTime: elapsedTime, created: new Date()})
  return

# extends the query object to ensure that all flights are filtered by current
# dates
#
# @param [Object] query, the incoming query object
# @param [String] lastId, the lastId for performing limit/offset by sorted _id
# @return [Object] query, the outgoing query object
extendQuery = (query, lastId) ->
  # all flights are filtered by current date being past the discontinuedDate
  # or before the effectiveDate
  now = new Date()
  if !_.isUndefined(query.effectiveDate)
    query.effectiveDate.$lte = new Date(query.effectiveDate.$lte)
  else
    query.effectiveDate = {$lte: now}
  if !_.isUndefined(query.discontinuedDate)
    query.discontinuedDate.$gte = new Date(query.discontinuedDate.$gte)
  else
    query.discontinuedDate = {$gte: now}

  # offset
  if !(_.isUndefined(lastId) or _.isNull(lastId))
    offsetFilter = _id: $gt: lastId
    _.extend query, offsetFilter

# cache the results of calling the given function for a period of time.
tempCache = (func)->
  ONE_DAY_IN_MILLISECONDS = 1000 * 60 * 60 * 24
  cache = {}
  return (args...)->
    key = args.join(',')
    if key of cache
      [result, timestamp] = cache[key]
      if (new Date() - timestamp) < ONE_DAY_IN_MILLISECONDS
        return result
    result = func.apply(this, args)
    cache[key] = [result, new Date()]
    return result

# builds the mongo options object that contains sort and limit clauses
#
# @param [Integer] limit, the amout to limit the results
# @return [Object] options, mongodb query options
buildOptions = (limit) ->
  options =
    sort:
      _id: 1

  # limit
  if !(_.isUndefined(limit) or _.isNull(limit))
    limitClause =
      limit: limit
    _.extend options, limitClause
  return options

# the query keys should have the most selective filters first, this method
# places the date keys prior to any other keys used in the filter.
#
# @param [Object] query, the incoming query object
# @return [Array] keys, arranged by selectiveness
arrangeQueryKeys = (query) ->
  keys = Object.keys(query)
  effectiveDateIdx = _.indexOf(keys, 'effectiveDate')
  if effectiveDateIdx > 0
    keys.splice(effectiveDateIdx, 1)
    keys.unshift('effectiveDate')
  discontinuedDateIdx = _.indexOf(keys, 'discontinuedDate')
  if discontinuedDateIdx > 0
    keys.splice(discontinuedDateIdx, 1)
    keys.unshift('discontinuedDate')
  return keys

# find flights with an optional limit and offset
#
# @param [Object] query, a mongodb query object
# @param [Integer] limit, the amount of records to limit
# @param [Integer] skip, the amount of records to skip
# @return [Array] an array of flights
flightsByQuery = (query, limit, skip) ->
  if _profile
    start = new Date()

  if _.isUndefined(query) or _.isEmpty(query)
    return []

  if _.isUndefined(limit)
    limit = 0
  if _.isUndefined(skip)
    skip = 0

  # make sure dates are set
  extendQuery(query, null)

  matches = []
  if _useAggregation
    # prepare the aggregate pipeline
    pipeline = [
      {$skip: skip},
      {$limit: limit}
    ]
    _.each(arrangeQueryKeys(query), (key) ->
      obj = {$match: {}}
      value = query[key]
      obj['$match'][key] = value
      pipeline.unshift(obj)
    )
    matches = Flights.aggregate(pipeline)
  else
    matches = Flights.find(query, {limit: limit, skip: skip, transform: null}).fetch()

  if _profile
    recordProfile('flightsByQuery', new Date() - start)
  return matches

# count the total flights for the specified query
#
# @param [Object] query, a mongodb query object
# @return [Integer] totalRecorts, the count of the query
countFlightsByQuery = (query) ->
  if _profile
    start = new Date()

  if _.isUndefined(query) or _.isEmpty(query)
    return 0

  extendQuery(query)

  count = Flights.find(query, {transform: null}).count()

  if _profile
    recordProfile('countFlightsByQuery', new Date() - start)
  return count

# finds airports that have flights
#
# @return [Array] airports, an array of airport document
findActiveAirports = tempCache () ->
  if _activeAirports isnt null
    return _activeAirports
  rawFlights = Flights.rawCollection()
  rawDistinct = Meteor.wrapAsync(rawFlights.distinct, rawFlights)
  _activeAirports = Airports.find({'_id': {$in: rawDistinct("departureAirport._id")}}).fetch()
  return _activeAirports

# finds a single airport document
#
# @param [String] id, the airport code to retrieve
# @return [Object] airport, an airport document
findAirportById = (id) ->
  if _.isUndefined(id) or _.isEmpty(id)
    return []
  return Airports.findOne({'_id': id})

startSimulation = (simPas, startDate, endDate, origins) ->
  future = new Future();
  HTTP.post(_FLIRT_SIMULATOR_URL, {
    params: {
      submittedBy: 'robo@noreply.io',
      startDate: startDate,
      endDate: endDate,
      departureNodes: origins,
      numberPassengers: simPas
    }
  }, (err, res) ->
    if err
      future.throw(err)
      return
    future.return(JSON.parse(res.content))
  )
  return future.wait()
# finds nearby airports through geo $near
#
# @param [String] id, the airport code to use as the center/base of search
# @return [Array] airports, an array of airports
findNearbyAirports = (id, miles) ->
  if _profile
    start = new Date()
  if _.isUndefined(id) or _.isEmpty(id)
    return []
  miles = parseInt(miles, 10)
  if _.isUndefined(miles) or _.isNaN(miles)
    return []
  metersToMiles = 1609.344
  airport = Airports.findOne({'_id': id})
  if _.isUndefined(airport) or _.isEmpty(airport)
    return []
  coordinates = airport.loc.coordinates
  value =
    $geometry:
      type: 'Point'
      coordinates: coordinates
    $minDistance: 0
    $maxDistance: metersToMiles * miles
  query =
    loc: {$near: value}
  airports = Airports.find(query, {transform: null}).fetch()
  if _profile
    recordProfile('findNearbyAirports', new Date() - start)
  return airports
# finds the min and max date range of a 'Date' key to the flights collection
#
# @param [String] the key of the flight documents the contains a date value
# @return [Array] array of two dates, defaults to 'null' if not found [min, max]
findMinMaxDateRange = tempCache (key) ->
  if _profile
    start = new Date()

  # determine minimum date by sort ascending
  minDate = null
  minResults = Flights.find({}, {sort: {"#{key}": 1}, limit: 1, transform: null}).fetch()
  if !(_.isUndefined(minResults) || _.isEmpty(minResults))
    min = minResults[0]
    if min.hasOwnProperty(key)
      minDate = min[key]

  # determine maximum date by sort descending
  maxDate = null
  maxResults = Flights.find({}, {sort: {"#{key}": -1}, limit: 1, transform: null}).fetch()
  if !(_.isUndefined(maxResults) || _.isEmpty(maxResults))
    max = maxResults[0]
    if max.hasOwnProperty(key)
      maxDate = max[key]

  if _profile
    recordProfile('findMinMaxDateRange', new Date() - start)
  return [minDate, maxDate]
# determines if the runtime environment is for testing
#
# @return [Boolean] isTest, true or false
isTestEnvironment = () ->
  return process.env.hasOwnProperty('VELOCITY_MAIN_APP_PATH')

# finds airports that match the search
#
# @param [String] search, the string to search for matches
# @param [Integer] skip, the amount of documents to skip in limit/offset
# @return [Array] airports, an array of airport documents
typeaheadAirport = (search, skip) ->
  if _profile
    start = new Date()
  if typeof skip == 'undefined'
    skip = 0
  fields = []
  for fieldName, matcher of Airport.typeaheadMatcher()
    field = {}
    field[fieldName] = {$regex: new RegExp(matcher.regexSearch({search: search}), matcher.regexOptions)}
    fields.push(field)

  matches = []
  if _useAggregation
    pipeline = [
      {$match: {$or: fields}},
      {$sort: {_id: 1}},
      {$skip: skip},
      {$limit: 10}
    ]
    matches = Airports.aggregate(pipeline)
  else
    query = { $or: fields }
    matches = Airports.find(query, {limit: 10, sort: {_id: 1}, skip: skip, transform: null}).fetch()
  if _profile
    recordProfile('typeaheadAirport', new Date() - start)
  return matches
# counts the number of airports that match the search
#
# @param [String] search, the string to search for matches
# @return [Integer] count, the number of documents matching the search
countTypeaheadAirports = (search) ->
  if _profile
    start = new Date()

  fields = []
  for fieldName, matcher of Airport.typeaheadMatcher()
    field = {}
    field[fieldName] = {$regex: new RegExp(matcher.regexSearch({search: search}), matcher.regexOptions)}
    fields.push(field)

  query = { $or: fields }
  count = Airports.find(query, {sort: {_id: 1}, transform: null}).count()

  if _profile
    recordProfile('countTypeaheadAirports', new Date() - start)
  return count

Meteor.publish 'SimulationItineraries', (simId) ->
  # query options
  options = {
    fields:
      simulationId: 1
      origin: 1
      destination: 1
    transform:
      null
  }
  if _.isEmpty(simId)
    return []
  console.log('Subscribed SimulationItineraries -- simId:%j --options: %j', simId, options)
  return Itineraries.find({simulationId: simId}, options)

# find a simulation by simId
#
# @param [String] simId
# @return [Object] simulations, a simulation documents
findSimulationBySimId = (simId) ->
  if _.isUndefined(simId) or _.isEmpty(simId)
    return {}
  return Simulations.findOne({'simId': simId})

# Public API
Meteor.methods
  startSimulation: startSimulation
  flightsByQuery: flightsByQuery
  countFlightsByQuery: countFlightsByQuery
  findActiveAirports: findActiveAirports
  findAirportById: findAirportById
  findNearbyAirports: findNearbyAirports
  findMinMaxDateRange: findMinMaxDateRange
  isTestEnvironment: isTestEnvironment
  typeaheadAirport: typeaheadAirport
  countTypeaheadAirports: countTypeaheadAirports
  findSimulationBySimId: findSimulationBySimId
