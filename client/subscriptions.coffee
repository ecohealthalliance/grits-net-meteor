Meteor.startup () ->
  Session.set 'flightsReady', false

# When the subscription is ready, set the flag to true
Tracker.autorun ->
  q = Session.get('query')
  
  if !_.isUndefined(q) or !_.isEmpty(q)
    Meteor.subscribe 'flightsByQuery', Session.get('query'),
      onError: ->
        console.log 'subscription.groupFlightsBy.onError:', this
        Session.set 'flightsReady', false
      onStop: ->
        console.log 'subscription.groupFlightsBy.onStop:', this
        Session.set 'flightsReady', false
      onReady: ->
        console.log 'subscription.groupFlightsBy.onReady', this
        Session.set 'flightsReady', true