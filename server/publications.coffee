Meteor.publish 'flightsByQuery', (query) ->
  if _.isUndefined(query) or _.isEmpty(query)
    return []

  # all flights are filtered by current date being past the discontinuedDate
  # or before the effectiveDate
  now = new Date()
  activeFilter =
    $and: [
      effectiveDate: {$lt: now}, # effectiveDate is less than now
      discontinuedDate: {$gte: now} # discontinuedDate is greater-equal than now
    ]
  _.extend(query, activeFilter);

  count = Flights.find(query).count()
  console.log 'query: ', query
  console.log 'count: ', count

  return Flights.find(query)

Meteor.publish 'autoCompleteAirports', (selector, options) ->
  console.log 'selector', selector
  Autocomplete.publishCursor(Airports.find(selector, options), this)
  this.ready()
