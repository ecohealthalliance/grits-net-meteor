Tracker.autorun ->
  query = Session.get('query')
  Meteor.subscribe 'flightsByQuery', query,
    onError: ->
      console.log 'subscription.flightsByQuery.onError: ', this
      Session.set('isUpdating',false)
      return
    onStop: ->
      console.log 'subscription.flightsByQuery.onStop: ', this
      return
    onReady: ->
      console.log 'subscription.flightsByQuery.onReady: ', this
      console.log 'subscription.query: ', query
      Meteor.gritsUtil.onSubscriptionReady()
      return
  return
