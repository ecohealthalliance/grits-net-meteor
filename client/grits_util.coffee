Meteor.startup ->
  Session.set 'grits-net-meteor:query', null
  Session.set 'grits-net-meteor:isUpdating', false
  Session.set 'grits-net-meteor:loadedRecords', 0
  Session.set 'grits-net-meteor:totalRecords', 0
  Session.set 'grits-net-meteor:limit', null
  Session.set 'grits-net-meteor:levels', 1
  Session.set 'grits-net-meteor:lastId', null

Meteor.gritsUtil =  
  debug: true
  errorHandler: (err) ->
    if typeof err != 'undefined'
      if err.hasOwnProperty('message')
        toastr.error(err.message)
      else
        toastr.error(err)
        console.error(err)
    Session.set('grits-net-meteor:isUpdating', false)
    return  
  processQueue: (res) ->
    map = Template.gritsMap.getInstance()
    nodeLayer = map.getGritsLayer('Nodes')
    pathLayer = map.getGritsLayer('Paths')
    nodeLayer.clear()
    pathLayer.clear()
  
    count = 0
    processQueue = async.queue(((flight, callback) ->
      nodes = nodeLayer.convertFlight(flight, GritsFilterCriteria.readDeparture())
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
      Session.set('grits-net-meteor:loadedRecords', count)
      Session.set('grits-net-meteor:isUpdating', false)
  
    processQueue.push(res)
    return
  processLimitQueue: (res) ->
    count =  Session.get('grits-net-meteor:loadedRecords')
    tcount = 0
    map = Template.gritsMap.getInstance()
    nodeLayer = map.getGritsLayer('Nodes')
    pathLayer = map.getGritsLayer('Paths')
  
    processQueue = async.queue(((flight, callback) ->
      nodes = nodeLayer.convertFlight(flight, GritsFilterCriteria.readDeparture())
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
      Session.set('grits-net-meteor:loadedRecords', count+res.length)
      Session.set('grits-net-meteor:isUpdating', false)
  
    processQueue.push(res)
    return
  # process
  #
  # This method is triggered with the 'flightsByQuery' callback returns.
  process: (flights, limit, levels) ->
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
          Meteor.gritsUtil.processQueue(res[0])
        return
    else
      if flights.length > 0      
        lastFlight = flights[flights.length-1]
        Template.gritsFilter.setLastFlightId(lastFlight.get('_id'))
        Meteor.gritsUtil.processQueue(flights)
    return
  # processLimit
  #
  # This method is triggered when the [More..] button is pressed in continuation
  # of a limit/offset query
  processLimit: (flights, limit, lastId, levels) ->
    if levels > 1
      query = GritsFilterCriteria.getQueryObject()
      origin = Template.gritsFilter.getOrigin()
      if !_.isNull(origin)
        Meteor.call 'getMoreFlightsByLevel', query, levels, origin, limit, lastId, (err, res) ->
          if Meteor.gritsUtil.debug
            console.log 'levelRecs: ', res[0]
          Session.set 'grits-net-meteor:totalRecords', res[1]
          Template.gritsFilter.setLastFlightId(res[2])
          Meteor.gritsUtil.processLimitQueue(res[0])
        return
    else
      if flights.length > 0      
        lastFlight = flights[flights.length-1]
        Template.gritsFilter.setLastFlightId(lastFlight.get('_id'))
        Meteor.gritsUtil.processLimitQueue(flights)
    return
    