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
          _onSubscriptionReady()
        else
          _onMoreSubscriptionsReady()
      return
  return


# processQueueCallback
#
#
_processQueueCallback = (res) ->
  Template.gritsMap.nodeLayer.clear()
  Template.gritsMap.pathLayer.clear()
  count = 0
  processQueue = async.queue(((flight, callback) ->
    nodes = Template.gritsMap.nodeLayer.convertFlight(flight)
    Template.gritsMap.pathLayer.convertFlight(flight, 1, nodes[0], nodes[1])
    async.nextTick ->
      if !(count % 100)
        Template.gritsMap.nodeLayer.draw()
        Template.gritsMap.pathLayer.draw()
      Session.set('grits-net-meteor:loadedRecords', ++count)
      callback()
  ), 1)

  # callback method for when all items within the queue are processed
  processQueue.drain = ->
    Template.gritsMap.nodeLayer.draw()
    Template.gritsMap.pathLayer.draw()
    Session.set('grits-net-meteor:loadedRecords', count)
    Session.set('grits-net-meteor:isUpdating', false)

  processQueue.push(res)
  return
  
# processMoreQueueCallback
#
#
_processMoreQueueCallback = (res) ->
  count =  Session.get('grits-net-meteor:loadedRecords')
  tcount = 0
  processQueue = async.queue(((flight, callback) ->
    nodes = Template.gritsMap.nodeLayer.convertFlight(flight)
    Template.gritsMap.pathLayer.convertFlight(flight, 1, nodes[0], nodes[1])
    async.nextTick ->
      if !(tcount % 100)
        Template.gritsMap.nodeLayer.draw()
        Template.gritsMap.pathLayer.draw()
        tcount++
      Session.set('grits-net-meteor:loadedRecords', count+res.length)
      callback()
  ), 1)

  # callback method for when all items within the queue are processed
  processQueue.drain = ->      
    Template.gritsMap.nodeLayer.draw()
    Template.gritsMap.pathLayer.draw()

    Session.set('grits-net-meteor:loadedRecords', count+res.length)
    Session.set('grits-net-meteor:isUpdating', false)

  processQueue.push(res)
  return

# onSubscriptionReady
#
# This method is triggered with the 'flightsByQuery' subscription onReady
# callback.  It gets the new flights from the collection and updates the
# existing nodes (airports) and paths (flights).
_onSubscriptionReady = () ->
  if parseInt($("#connectednessLevels").val()) > 1
    query = GritsFilterCriteria.getQueryObject()
    origin = Template.gritsFilter.getOrigin()
    if !_.isNull(origin)
      Meteor.call 'getFlightsByLevel', query, parseInt($("#connectednessLevels").val()), origin, Session.get('grits-net-meteor:limit'), (err, res) ->
        if Meteor.gritsUtil.debug
          console.log 'levelRecs: ', res[0]
        Session.set 'grits-net-meteor:totalRecords', res[1]
        if !_.isUndefined(res[2]) and !_.isEmpty(res[2])
          Template.gritsFilter.setLastFlightId(res[2])
        _processQueueCallback(res[0])
      return

  tflights = Flights.find().fetch()
  Template.gritsFilter.setLastFlightId()
  _processQueueCallback(tflights)

# _onMoreSubscriptionsReady
#
# This method is triggered when the [More..] button is pressed in continuation
# of a limit/offset query
_onMoreSubscriptionsReady = () ->
  if parseInt($("#connectednessLevels").val()) > 1
    query = GritsFilterCriteria.getQueryObject()
    origin = Template.gritsFilter.getOrigin()
    if !_.isNull(origin)
      Meteor.call 'getMoreFlightsByLevel', query, parseInt($("#connectednessLevels").val()), origin, Session.get('grits-net-meteor:limit'), Session.get('grits-net-meteor:lastId'), (err, res) ->
        if Meteor.gritsUtil.debug
          console.log 'levelRecs: ', res[0]
        Session.set 'grits-net-meteor:totalRecords', res[1]
        Template.gritsFilter.setLastFlightId(res[2])
        _processMoreQueueCallback(res[0])
      return
  
  tflights = Flights.find().fetch()
  Template.gritsFilter.setLastFlightId()
  _processMoreQueueCallback(tflights)