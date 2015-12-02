Tracker.autorun ->
  query = Session.get('grits-net-meteor:query')
  if _.isUndefined(query) or _.isEmpty(query)
    return

  limit = Session.get('grits-net-meteor:limit')
  lastId = Session.get('grits-net-meteor:lastId')
  Session.set 'grits-net-meteor:isUpdating', true

  Meteor.call('flightsByQuery', query, limit, lastId, (err, flights) ->
    if (err)
      console.error(err)
      Session.set('grits-net-meteor:isUpdating', false)
      return
    
    if _.isUndefined(flights)
      Session.set('grits-net-meteor:isUpdating', false)
      return
    
    Meteor.call 'countFlightsByQuery', query, (err, totalRecords) ->
      if (err)
        console.error(err)
        Session.set('grits-net-meteor:isUpdating', false)
        return
    
      if Meteor.gritsUtil.debug
        console.log 'totalRecords: ', totalRecords
    
      if lastId is null
        Session.set 'grits-net-meteor:totalRecords', totalRecords
        _process(flights, limit)
      else
        _processLimit(flights, limit, lastId)
    return
  )
  return

# processQueue
#
#
_processQueue = (res) ->
  map = Template.gritsMap.getInstance()
  nodeLayer = map.getGritsLayer('Nodes')
  pathLayer = map.getGritsLayer('Paths')
  nodeLayer.clear()
  pathLayer.clear()

  count = 0
  processQueue = async.queue(((flight, callback) ->
    nodes = nodeLayer.convertFlight(flight)
    pathLayer.convertFlight(flight, 1, nodes[0], nodes[1])
    async.nextTick ->
      if !(count % 100)
        nodeLayer.draw()
        pathLayer.draw()
      Session.set('grits-net-meteor:loadedRecords', ++count)
      callback()
  ), 1)

  # callback method for when all items within the queue are processed
  processQueue.drain = ->
    nodeLayer.draw()
    pathLayer.draw()
    Template.gritsMap.updateFlightTable()
    Session.set('grits-net-meteor:loadedRecords', count)
    Session.set('grits-net-meteor:isUpdating', false)

  processQueue.push(res)
  return

# processLimitQueue
#
#
_processLimitQueue = (res) ->
  count =  Session.get('grits-net-meteor:loadedRecords')
  tcount = 0
  map = Template.gritsMap.getInstance()
  nodeLayer = map.getGritsLayer('Nodes')
  pathLayer = map.getGritsLayer('Paths')

  processQueue = async.queue(((flight, callback) ->
    nodes = nodeLayer.convertFlight(flight)
    pathLayer.convertFlight(flight, 1, nodes[0], nodes[1])
    async.nextTick ->
      if !(tcount % 100)
        nodeLayer.draw()
        pathLayer.draw()
        tcount++
      Session.set('grits-net-meteor:loadedRecords', count+res.length)
      callback()
  ), 1)

  # callback method for when all items within the queue are processed
  processQueue.drain = ->
    nodeLayer.draw()
    pathLayer.draw()
    Template.gritsMap.updateFlightTable()
    Session.set('grits-net-meteor:loadedRecords', count+res.length)
    Session.set('grits-net-meteor:isUpdating', false)

  processQueue.push(res)
  return

# _process
#
# This method is triggered with the 'flightsByQuery' callback returns.
_process = (flights, limit) ->
  levels = parseInt($("#connectednessLevels").val(), 10)
  if levels > 1
    query = GritsFilterCriteria.getQueryObject()
    origin = Template.gritsFilter.getOrigin()
    if !_.isNull(origin)
      Meteor.call 'getFlightsByLevel', query, levels, origin, limit, (err, res) ->
        if Meteor.gritsUtil.debug
          console.log 'levelRecs: ', res[0]
        Session.set 'grits-net-meteor:totalRecords', res[1]
        if !_.isUndefined(res[2]) and !_.isEmpty(res[2])
          Template.gritsFilter.setLastFlightId(res[2])
        _processQueue(res[0])
      return
  else
    if flights.length > 0      
      lastFlight = flights[flights.length-1]
      Template.gritsFilter.setLastFlightId(lastFlight.get('_id'))
      _processQueue(flights)
  return

# _processLimit
#
# This method is triggered when the [More..] button is pressed in continuation
# of a limit/offset query
_processLimit = (flights, limit, lastId) ->
  levels = parseInt($("#connectednessLevels").val(), 10)
  if levels > 1
    query = GritsFilterCriteria.getQueryObject()
    origin = Template.gritsFilter.getOrigin()
    if !_.isNull(origin)
      Meteor.call 'getMoreFlightsByLevel', query, levels, origin, limit, lastId, (err, res) ->
        if Meteor.gritsUtil.debug
          console.log 'levelRecs: ', res[0]
        Session.set 'grits-net-meteor:totalRecords', res[1]
        Template.gritsFilter.setLastFlightId(res[2])
        _processLimitQueue(res[0])
      return
  else
    if flights.length > 0      
      lastFlight = flights[flights.length-1]
      Template.gritsFilter.setLastFlightId(lastFlight.get('_id'))
      _processLimitQueue(flights)
  return
