###*
* Flights that are expired, past Discontinued Date, do not include in map
* Flights that are not yet active, before Effective Date, do not include in map
###

Meteor.publish 'flightsByQuery', (query) ->
    return Flights.find(query);