# creates an instance of a node
#
# @param [Object] obj, an object that represents a node, it must contain a unique _id and a geoJSON 'loc' property
# @param [Object] marker, an instance of GritsMarker
class GritsNode
  constructor: (obj, marker) ->

    if typeof obj == 'undefined' or obj == null
      throw new Error('A node requires valid input object')
      return

    if obj.hasOwnProperty('_id') == false
      throw new Error('A node requires the "_id" unique identifier property')
      return

    if obj.hasOwnProperty('loc') == false
      throw new Error('A node requires the "loc" geoJSON location property')
      return

    longitude = obj.loc.coordinates[0]
    latitude = obj.loc.coordinates[1]

    @_id = obj._id
    @_name = 'GritsNode'

    if typeof marker != 'undefined' and marker instanceof GritsMarker
      @marker = marker
    else
      @marker = new GritsMarker()

    @latLng = [latitude, longitude]

    @incomingThroughput = 0
    @outgoingThroughput = 0
    @level = 0

    # to save on memory, the node details is stored in a global object `Meteor.gritsUtil.airports`
    # and not embedded into each node displayed on the map.
    #@metadata = {}
    #_.extend(@metadata, obj)

    @eventHandlers = {}

    return

  # binds eventHandlers to the node
  #
  # @param [Object] eventHandlers, an object containing event handlers
  setEventHandlers: (eventHandlers) ->
    for name, method of eventHandlers
      @eventHandlers[name] = _.bind(method, this)

  # sum throughput for the node, checks if flight has 'seatsOverInterval' property
  sumThroughput: (flight) ->
    self = this
    if flight.hasOwnProperty('seatsOverInterval')
      # the flight interval was grated than a single day, increment by seatsOverInterval
      if flight.seatsOverInterval > 0
        self.throughput += Math.round(flight.seatsOverInterval)
      # the flight interval was a single day, increment by totalSeats
      else
        self.throughput += Math.round(flight.totalSeats)
    else
      console.warn('flight is missing seatsOverInterval property: ', flight)
      self.throughput += Math.round(flight.totalSeats)
    return
    
