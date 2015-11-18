Tracker.autorun ->
  query = Session.get('grits-net-meteor:query')
  if _.isUndefined(query) or _.isEmpty(query)
    return

  limit = Session.get('grits-net-meteor:limit')
  lastId = Session.get('grits-net-meteor:lastId')
  Session.set 'grits-net-meteor:isUpdating', true

  Meteor.subscribe 'flightsByQuery', query, limit, lastId,
    onError: ->
      if Meteor.gritsUtil.debug
        console.log 'subscription.flightsByQuery.onError: ', this
      Session.set('grits-net-meteor:isUpdating',false)
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
          Session.set 'grits-net-meteor:totalRecords', res
          Meteor.gritsUtil.onSubscriptionReady()
        else
          Meteor.gritsUtil.onMoreSubscriptionsReady()
      return
  return
