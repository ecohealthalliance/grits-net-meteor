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
    originsByLevel[1] = origin
    while ctr < levels
      flights = Flights.find(query, buildOptions(null)).fetch()
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
    for flight of flightsByLevel
      console.log 'flightsByLevel:' , flight + ' lev :' + flightsByLevel[flight].length
    console.log 'originsByLevel: ', originsByLevel
    for origins of originsByLevel
      Array::push.apply allOrigins, originsByLevel[origins]
    console.log 'allOrigins: ', allOrigins
    query['departureAirport._id'] = {'$in':allOrigins}
    nullOpts = buildOptions(null)
    console.log 'allQuery: ', query
    console.log 'allOpts: ', nullOpts
    allFlights = Flights.find(query, nullOpts).fetch()
    console.log 'allFlights: ', allFlights.length
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
      console.log 'limit: ', limit
      console.log 'limitRemainder: ', limitRemainder
      console.log 'flightsToReturn: ', flightsToReturn.length
      console.log 'retFlightCount: ', retFlightCount
      console.log 'retFlightByLevIndex: ', retFlightByLevIndex
      if limitRemainder > 0
        trailingFlights = []
        remainderOPTS = buildOptions(limitRemainder)
        cpol = originsByLevel[retFlightByLevIndex]
        query['departureAirport._id'] = {'$in':cpol}
        console.log 'queryTrail: ', query
        trailingFlights = Flights.find(query, remainderOPTS).fetch()
        console.log 'trailingFlights: ', trailingFlights.length
        Array::push.apply flightsToReturn, trailingFlights
      return [flightsToReturn, allFlights.length, flightsToReturn[flightsToReturn.length-1]._id]

Meteor.methods
  countFlightsByQuery: (query) ->
    if _.isUndefined(query) or _.isEmpty(query)
      return 0

    extendQuery(query, null)
    buildOptions(null)

    return Flights.find(query).count()
  typeaheadAirport: (search, options) ->
    query = {
      $or: [
        {_id: {$regex: new RegExp(search, 'i')}},
        {city: {$regex: new RegExp(search, 'ig')}}
      ]
    }
    return Airports.find(query, {limit: 10, sort: {_id: 1}}).fetch()

Meteor.publish 'autoCompleteAirports', (query, options) ->
  Autocomplete.publishCursor(Airports.find(query, options), this)
  this.ready()
