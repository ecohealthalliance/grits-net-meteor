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

Meteor.methods
  flightsByQuery: (query, limit, lastId) ->
    if _.isUndefined(query) or _.isEmpty(query)
      return []

    extendQuery(query, lastId)

    options = buildOptions(limit)

    console.log 'query: %j', query
    console.log 'options: %j', options

    return Flights.find(query, options).fetch()

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
  countFlightsByQuery: (query) ->
    if _.isUndefined(query) or _.isEmpty(query)
      return 0

    extendQuery(query, null)
    buildOptions(null)

    count = Flights.find(query).count()
    console.log('countFlightsByQuery:query: %j', query)
    console.log('countFlightsByQuery:count: %j', count)
    return count
  findHeatmapByCode: (code) ->
    if _.isUndefined(code) or _.isEmpty(code)
      return {}
    heatmap = Heatmaps.findOne({'_id': code})
    return heatmap
  findHeatmapsByCodes: (codes) ->
    console.log('findHeatmapsByCodes: %j', codes)
    if _.isUndefined(codes) or _.isEmpty(codes)
      return []
    heatmaps = Heatmaps.find({'_id': {'$in': codes}}).fetch()
    return heatmaps
  findAirportById: (id) ->
    if _.isUndefined(id) or _.isEmpty(id)
      return []
    return Airports.findOne({'_id': id})
  findNearbyAirports: (id, miles) ->
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
    console.log('findNearbyAirports:query: %j', query)
    airports = Airports.find(query).fetch()
    return airports
  # finds the min and max date range of a 'Date' key to the flights collection
  #
  # @param [String] the key of the flight documents the contains a date value
  # @return [Array] array of two dates, defaults to 'null' if not found [min, max]
  findMinMaxDateRange: (key) ->
    # determine minimum date by sort ascending
    minDate = null
    minPipeline = [
      {$sort: {"#{key}": 1}},
      {$limit: 1}
    ]
    minResults = Flights.aggregate(minPipeline)
    if !(_.isUndefined(minResults) || _.isEmpty(minResults))
      min = minResults[0]
      if min.hasOwnProperty(key)
        minDate = min[key]
    # determine maximum date by sort descending
    maxDate = null
    maxPipeline = [
      {$sort: {"#{key}": -1}},
      {$limit: 1}
    ]
    maxResults = Flights.aggregate(maxPipeline)
    if !(_.isUndefined(maxResults) || _.isEmpty(maxResults))
      max = maxResults[0]
      if max.hasOwnProperty(key)
        maxDate = max[key]
    return [minDate, maxDate]
  isTestEnvironment: () ->    
    return process.env.hasOwnProperty('VELOCITY_MAIN_APP_PATH')
  
Meteor.methods
  # find airports that match the search
  typeaheadAirport: (search, skip, options) ->
    start = new Date()
    if typeof skip == 'undefined'
      skip = 0
    fields = []
    for fieldName, matcher of Airport.typeaheadMatcher()
      field = {}
      field[fieldName] = {$regex: new RegExp(matcher.regexSearch({search: search}), matcher.regexOptions)}
      fields.push(field)
    pipeline = [
      {$match: {$or: fields}},
      {$sort: {_id: 1}},
      {$skip: skip},
      {$limit: 10}
    ]
    matches = Airports.aggregate(pipeline)
    ###
    query = { $or: fields }
    matches = Airports.find(query, {limit: 10, sort: {_id: 1}, skip: skip}).fetch()
    ###
    console.log('typeaheadAirport:timeTaken(ms): ', new Date() - start)
    return matches
  countTypeaheadAirports: (search, options) ->
    fields = []
    for fieldName, matcher of Airport.typeaheadMatcher()
      field = {}
      field[fieldName] = {$regex: new RegExp(matcher.regexSearch({search: search}), matcher.regexOptions)}
      fields.push(field)
    query = { $or: fields }
    return Airports.find(query, {sort: {_id: 1}}).count()
