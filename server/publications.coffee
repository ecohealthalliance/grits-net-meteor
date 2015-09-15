###*
* Flights that are expired, past Discontinued Date, do not include in map
* Flights that are not yet active, before Effective Date, do not include in map
###

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

  return Flights.find(query);
