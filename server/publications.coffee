extendQuery = (query, lastId) ->
  # all flights are filtered by current date being past the discontinuedDate
  # or before the effectiveDate
  if !_.isUndefined(query.effectiveDate)
    query.effectiveDate.$lte = new Date(query.effectiveDate.$lte)
  if !_.isUndefined(query.discontinuedDate)
    query.discontinuedDate.$gte = new Date(query.discontinuedDate.$gte)
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
  countFlightsByQuery: (query) ->
    if _.isUndefined(query) or _.isEmpty(query)
      return 0

    extendQuery(query, null)
    buildOptions(null)

    count = Flights.find(query).count()
    console.log('countFlightsByQuery: %j', count)
    return count

  typeaheadAirport: (search, options) ->
    query = {
      $or: [
        #regex = new RegExp(".*?(?:^|\s)(#{search}[^\s$]*).*?", 'ig')
        {_id: {$regex: new RegExp(search, 'i')}},
        {name: {$regex: new RegExp(search, 'i')}},
        {city: {$regex: new RegExp(search, 'ig')}},
        {state: {$regex: new RegExp(search, 'ig')}},
        {stateName: {$regex: new RegExp(search, 'ig')}},
        {country: {$regex: new RegExp(search, 'ig')}},
        {countryName: {$regex: new RegExp(search, 'ig')}},
        {globalRegion: {$regex: new RegExp(search, 'ig')}},
        {WAC: {$regex: new RegExp(search, 'ig')}}
        {notes: {$regex: new RegExp(search, 'ig')}}
      ]
    }
    return Airports.find(query, {limit: 10, sort: {_id: 1}}).fetch()

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

Meteor.publish 'autoCompleteAirports', (query, options) ->
  Autocomplete.publishCursor(Airports.find(query, options), this)
  this.ready()

Meteor.methods
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
