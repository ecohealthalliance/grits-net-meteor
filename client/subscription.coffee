Tracker.autorun ->
  query = Session.get('query')
  if _.isUndefined(query) or _.isEmpty(query)
    return

  limit = Session.get('limit')
  lastId = Session.get('lastId')
  Session.set 'isUpdating', true

  Meteor.subscribe 'flightsByQuery', query, limit, lastId,
    onError: ->
      if Meteor.gritsUtil.debug
        console.log 'subscription.flightsByQuery.onError: ', this
      Session.set('isUpdating',false)
      return
    onStop: ->
      if Meteor.gritsUtil.debug
        console.log 'subscription.flightsByQuery.onStop: ', this
      return
    onReady: ->
      if Meteor.gritsUtil.debug
        console.log 'subscription.flightsByQuery.onReady: ', this
        console.log 'subscription.query: ', query
      totalRecords = Meteor.call 'countFlightsByQuery', query, (err, res) ->
        if Meteor.gritsUtil.debug
          console.log 'totalRecords: ', res
        if lastId is null
          Session.set 'totalRecords', res
          Meteor.gritsUtil.onSubscriptionReady()
        else
          Meteor.gritsUtil.onMoreSubscriptionsReady()
      return
  return
