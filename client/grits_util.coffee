Meteor.startup ->
  Session.set 'grits-net-meteor:query', null
  Session.set 'grits-net-meteor:isUpdating', false
  Session.set 'grits-net-meteor:loadedRecords', 0
  Session.set 'grits-net-meteor:totalRecords', 0
  Session.set 'grits-net-meteor:limit', null
  Session.set 'grits-net-meteor:lastId', null

Meteor.gritsUtil =  
  debug: true
  processQueueCallback: (self, res) ->
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

    processQueue.push(res);

  processMoreQueueCallback: (self, res) ->
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

    processQueue.push(res);

  # onSubscriptionReady
  #
  # This method is triggered with the 'flightsByQuery' subscription onReady
  # callback.  It gets the new flights from the collection and updates the
  # existing nodes (airports) and paths (flights).
  onSubscriptionReady: ->
    self = this
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
          self.processQueueCallback(self, res[0])
        return

    tflights = Flights.find().fetch()
    Template.gritsFilter.setLastFlightId()
    self.processQueueCallback(self, tflights)

  # onMoreSubscriptionsReady
  #
  # This method is triggered when the [More..] button is pressed in continuation
  # of a limit/offset query
  onMoreSubscriptionsReady: ->
    self = this
    if parseInt($("#connectednessLevels").val()) > 1
      query = GritsFilterCriteria.getQueryObject()
      origin = Template.gritsFilter.getOrigin()
      if !_.isNull(origin)
        Meteor.call 'getMoreFlightsByLevel', query, parseInt($("#connectednessLevels").val()), origin, Session.get('grits-net-meteor:limit'), Session.get('grits-net-meteor:lastId'), (err, res) ->
          if Meteor.gritsUtil.debug
            console.log 'levelRecs: ', res[0]
          Session.set 'grits-net-meteor:totalRecords', res[1]
          Template.gritsFilter.setLastFlightId(res[2])
          self.processMoreQueueCallback(self,res[0])
        return
    
    tflights = Flights.find().fetch()
    Template.gritsFilter.setLastFlightId()
    self.processMoreQueueCallback(self,tflights)