_useAggregation = true # enable/disable using the aggregation framework
_profile = false # enable/disable inserting profiling times to the database

# collection to record profiling results
Profiling = new Mongo.Collection('profiling')
recordProfile = (methodName, elapsedTime) ->
  Profiling.insert({methodName: methodName, elapsedTime: elapsedTime, created: new Date()})
  return

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

# the query keys should have the most selective filters first, this method
# places the date keys prior to any other keys used in the filter.
#
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

Meteor.methods
  # method to query flights with an optional limit and offset
  #
  # @param [Object] query, a mongodb query object
  # @param [Integer] limit, the amount of records to limit
  # @param [Integer] skip, the amount of records to skip
  # @return [Array] an array of flights
  flightsByQuery: (query, limit, skip) ->
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
        obj = {$match:{}}
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
    allOrigins = []
    origin = [origin]
    originsByLevel[1] = origin
    while ctr < levels
      console.log('getFlightsByLevel:query# %j: %j', ctr, query)
      flights = Flights.find({'$query':query, '$hint': 'idxFlights_Default', '$orderBy': {'_id': 1}}, {'limit': limit}).fetch()
      #flights = Flights.find(query, buildOptions(null)).fetch()
      flightsByLevel[ctr] = flights
      originsByLevel[ctr+1] = []
      for flight of flights
        addtoObl = true
        addtoAll = true
        for origin of originsByLevel
          for oid of originsByLevel[origin]
            if originsByLevel[origin][oid] is flights[flight].arrivalAirport._id
              addtoObl = false
              break
        if addtoObl
          originsByLevel[ctr+1].push(flights[flight].arrivalAirport._id)
      query['departureAirport._id'] = {'$in':originsByLevel[ctr+1]}
      ctr++
    for origins of originsByLevel
      Array::push.apply allOrigins, originsByLevel[origins]
    query['departureAirport._id'] = {'$in':allOrigins}
    nullOpts = buildOptions(null)
    console.log('allFlights:query: %j', query)
    #allFlights = Flights.find(query, nullOpts).fetch()
    allFlights = Flights.find({'$query':query, '$hint': 'idxFlights_Default', '$orderBy': {'_id': 1}}).fetch() #no limit
    if limit is null or limit is 0 #no limit specified
      return [allFlights, allFlights.length]
    else
      retFlightCount = 0  # number of flights currently to return
      retFlightByLevIndex = 1 #level of returned flights based on index
      for flights of flightsByLevel
        if flightsByLevel[flights].length <= (limit - retFlightCount)
          retFlightCount += flightsByLevel[flights].length
          retFlightByLevIndex++
          continue
        else
          break
      limitRemainder = limit - retFlightCount
      flightsToReturn = []
      for flights of flightsByLevel
        if flights < retFlightByLevIndex
          Array::push.apply flightsToReturn, flightsByLevel[flights]
      lastId = null
      if limitRemainder > 0
        trailingFlights = []
        remainderOPTS = buildOptions(limitRemainder)
        cpol = originsByLevel[retFlightByLevIndex]
        query['departureAirport._id'] = {'$in':cpol}
        console.log('trailingFlights:query: %j', query)
        #trailingFlights = Flights.find(query, remainderOPTS).fetch()
        trailingFlights = Flights.find({'$query':query, '$hint': 'idxFlights_Default', '$orderBy': {'_id': 1}}, {'limit': limitRemainder}).fetch()
        Array::push.apply flightsToReturn, trailingFlights
        lastId = flightsToReturn[flightsToReturn.length-1]._id
      return [flightsToReturn, allFlights.length, lastId]

Meteor.methods
  getMoreFlightsByLevel: (query, levels, origin, limit, lastId) ->
    if _.isUndefined(query) or _.isEmpty(query)
      return 'query is empty'
    if levels < 2
      return 'levels is less than two: ' + levels
    extendQuery(query, null)
    ctr = 1
    flightsByLevel = []
    originsByLevel = []
    allOrigins = []
    originsByLevel[1] = origin
    totalFlights = 0
    while ctr <= levels
      console.log('getMoreFlightsByLevel:query# %j: %j', ctr, query)
      flights = Flights.find({'$query':query, '$hint': 'idxFlights_DepartureAirportStopsTotalSeatsWeeklyFrequency', '$orderBy': {'_id': 1}}, {'limit': limit}).fetch()
      #flights = Flights.find(query, buildOptions(null)).fetch()
      totalFlights += flights.length
      flightsByLevel[ctr] = flights
      originsByLevel[ctr+1] = []
      for flight of flights
        addtoObl = true
        addtoAll = true
        for origin of originsByLevel
          for oid of originsByLevel[origin]
            if originsByLevel[origin][oid] is flights[flight].arrivalAirport._id
              addtoObl = false
              break
        if addtoObl
          originsByLevel[ctr+1].push(flights[flight].arrivalAirport._id)
      query['departureAirport._id'] = {'$in':originsByLevel[ctr+1]}
      ctr++
    limitReached = false
    addToReturn = false
    flightsToReturn = []
    skipped = 0
    for flights of flightsByLevel
      if limit is flightsToReturn.length
        break
      for flight of flightsByLevel[flights]
        skipped++
        if flightsByLevel[flights][flight]._id is lastId
          addToReturn = true
          continue
        else
          if addToReturn
            if limit is flightsToReturn.length
              break
            else
              flightsToReturn.push(flightsByLevel[flights][flight])
    newLastId = null
    if flightsToReturn.length > 0
      if _.isUndefined(flightsToReturn[flightsToReturn.length-1]._id) is false
        newLastId = flightsToReturn[flightsToReturn.length-1]._id
    return [flightsToReturn, totalFlights, newLastId]

Meteor.methods
  # method to count the total flights for the specified query
  #
  # @param [Object] query, a mongodb query object
  # @return [Integer] totalRecorts, the count of the query
  countFlightsByQuery: (query) ->
    if _profile
      start = new Date()

    if _.isUndefined(query) or _.isEmpty(query)
      return 0

    extendQuery(query)

    count = 0
    if _useAggregation
      pipeline = []
      _.each(arrangeQueryKeys(query), (key) ->
        obj = {$match:{}}
        value = query[key]
        obj['$match'][key] = value
        pipeline.unshift(obj)
      )
      count = Flights.aggregate(pipeline).length
    else
      count = Flights.find(query, {transform:null}).count()

    if _profile
      recordProfile('countFlightsByQuery', new Date() - start)
    return count
  findHeatmapByCode: (code) ->
    if _.isUndefined(code) or _.isEmpty(code)
      return {}
    heatmap = Heatmaps.findOne({'_id': code})
    return heatmap
  findHeatmapsByCodes: (codes) ->
    if _.isUndefined(codes) or _.isEmpty(codes)
      return []
    heatmaps = Heatmaps.find({'_id': {'$in': codes}}, {transform: null}).fetch()
    return heatmaps
  findAirports: () ->
    if _profile
      start = new Date()
    airports = Airports.find({}, {transform: null}).fetch()
    if _profile
      recordProfile('findAirports', new Date() - start)
    return airports
  findAirportById: (id) ->
    if _.isUndefined(id) or _.isEmpty(id)
      return []
    return Airports.findOne({'_id': id})
  findNearbyAirports: (id, miles) ->
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
    airports = Airports.find(query, {transform:null}).fetch()
    if _profile
      recordProfile('findNearbyAirports', new Date() - start)
    return airports
  # finds the min and max date range of a 'Date' key to the flights collection
  #
  # @param [String] the key of the flight documents the contains a date value
  # @return [Array] array of two dates, defaults to 'null' if not found [min, max]
  findMinMaxDateRange: (key) ->
    if _profile
      start = new Date()

    # determine minimum date by sort ascending
    minDate = null
    minResults = []
    if _useAggregation
      minPipeline = [
        {$sort: {"#{key}": 1}},
        {$limit: 1}
      ]
      minResults = Flights.aggregate(minPipeline)
    else
      minResults = Flights.find({}, {sort: {"#{key}": 1}, limit:1, transform: null}).fetch()
    if !(_.isUndefined(minResults) || _.isEmpty(minResults))
      min = minResults[0]
      if min.hasOwnProperty(key)
        minDate = min[key]

    # determine maximum date by sort descending
    maxDate = null
    maxResults = []
    if _useAggregation
      maxPipeline = [
        {$sort: {"#{key}": -1}},
        {$limit: 1}
      ]
      maxResults = Flights.aggregate(maxPipeline)
    else
      maxResults = Flights.find({}, {sort: {"#{key}": -1}, limit:1, transform: null}).fetch()
    if !(_.isUndefined(maxResults) || _.isEmpty(maxResults))
      max = maxResults[0]
      if max.hasOwnProperty(key)
        maxDate = max[key]

    if _profile
      recordProfile('findMinMaxDateRange', new Date() - start)
    return [minDate, maxDate]
  isTestEnvironment: () ->
    return process.env.hasOwnProperty('VELOCITY_MAIN_APP_PATH')

Meteor.methods
  # find airports that match the search
  typeaheadAirport: (search, skip, options) ->
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
  countTypeaheadAirports: (search, options) ->
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
