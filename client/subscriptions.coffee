# Initialize default query parameter and set flag flightsReady to false
Session.set 'query',
    'Dest._id':'JFK',
    'Seats': {$gt: 250}
Session.set 'flightsReady', false

# When the subscription is ready, set the flag to true
Tracker.autorun ->
  Meteor.subscribe 'flightsByQuery', Session.get('query'),
    onError: ->
      console.log 'subscription.groupFlightsBy.onError:', this
      return
    onStop: ->
      console.log 'subscription.groupFlightsBy.onStop:', this
      return
    onReady: ->
      console.log 'subscription.groupFlightsBy.onReady', this
      Session.set 'flightsReady', true
      return

  return
