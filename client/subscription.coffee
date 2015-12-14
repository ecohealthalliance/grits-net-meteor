Tracker.autorun ->
  query = Session.get('grits-net-meteor:query')
  if _.isUndefined(query) or _.isEmpty(query)
    return

  limit = Session.get('grits-net-meteor:limit')
  lastId = Session.get('grits-net-meteor:lastId')
  levels = Session.get('grits-net-meteor:levels')
  
  Session.set 'grits-net-meteor:isUpdating', true

  Meteor.call('flightsByQuery', query, limit, lastId, (err, flights) ->
    if (err)
      Meteor.gritsUtil.handleError(err)
      return
    
    if _.isUndefined(flights) || flights.length <= 0
      toastr.info('The filter did not return any results')
      Session.set('grits-net-meteor:isUpdating', false)        
      return
    
    Meteor.call 'countFlightsByQuery', query, (err, totalRecords) ->
      if (err)
        Meteor.gritsUtil.handleError(err)
        return
    
      if Meteor.gritsUtil.debug
        console.log 'totalRecords: ', totalRecords
      
      if levels <= 1
        Session.set 'grits-net-meteor:totalRecords', totalRecords
    
      if lastId is null        
        Meteor.gritsUtil.process(flights, limit, levels)
      else
        Meteor.gritsUtil.processLimit(flights, limit, lastId, levels)
    return
  )
  return