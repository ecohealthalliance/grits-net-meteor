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
  typeaheadAirport: (search, options) ->
    regex = new RegExp("^" + search, 'ig');
    query = {
      $or: [
        {_id: {$regex: new RegExp("^" + search, 'i')}},
        {city: {$regex: new RegExp("^" + search, 'ig')}}
      ]
    }
    console.log('query: ', query)
    return Airports.find(query, {limit: 10, sort: {_id: 1}}).fetch()
  
Meteor.publish 'autoCompleteAirports', (query, options) ->
  Autocomplete.publishCursor(Airports.find(query, options), this)
  this.ready()
