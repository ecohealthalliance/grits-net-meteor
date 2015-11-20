# Template.gritsFilter
#
# When another meteor app adds grits:grits-net-meteor as a package
# Template.gritsFilter will be available globally.

_lastFlightId = null # stores the last flight _id from the collection, used in limit/offset

# getLastFlightId
#
#
Template.gritsFilter.getLastFlightId = () ->
  _lastFlightId

# setLastFlightId
#
#
Template.gritsFilter.setLastFlightId = (lastId) ->
  if !_.isUndefined(lastId)
    _lastFlightId = lastId
    return
  lastFlight = null
  if Flights.find().count() > 0
    options =
      sort:
        _id: -1
    lastFlight = Flights.find({}, options).fetch()[0];
  if lastFlight
    _lastFlightId = lastFlight._id

# getOrigin
#
#
Template.gritsFilter.getOrigin = () ->
  query = GritsFilterCriteria.getQueryObject()
  if _.has(query, 'departureAirport._id')
    # the filter has an array of airports 
    if _.has(query['departureAirport._id'], '$in')
      origins = query['departureAirport._id']['$in']
      if _.isArray(origins) and origins.length > 0
        return origins[0]
  return null


# helpers
#
# Sets an object to be used by Meteors' Blaze templating engine (views)
Template.gritsFilter.helpers({
  loadedRecords: () ->
    return Session.get 'grits-net-meteor:loadedRecords'
  totalRecords: () ->
    return Session.get 'grits-net-meteor:totalRecords'
})


# onRendered
#
# triggered when the 'filter' template is rendered
Template.gritsFilter.onRendered ->
  # Methods to use are:
  #  Template.gritsFilter.departureSearchMain.tokenfield('getTokens')
  #  Template.gritsFilter.departureSearchMain.tokenfield('setTokens', someNewTokenArray)
  #  See: http://sliptree.github.io/bootstrap-tokenfield/#methods
  Template.gritsFilter.departureSearchMain = $('#departureSearchMain').tokenfield({
    typeahead: [null, { source: (query, callback) ->
      Meteor.call('typeaheadAirport', query, (err, res) ->
        if err or _.isUndefined(res) or _.isEmpty(res)
          return
        else
          callback(res.map( (v) -> {value: v._id + " - " + v.city, label: v._id} ))
      )
    }]
  })
  # Methods to use are:
  #  Template.gritsFilter.departureSearch.tokenfield('getTokens')
  #  Template.gritsFilter.departureSearch.tokenfield('setTokens', someNewTokenArray)
  #  See: http://sliptree.github.io/bootstrap-tokenfield/#methods
  Template.gritsFilter.departureSearch = $('#departureSearch').tokenfield({
    typeahead: [null, { source: (query, callback) ->
      Meteor.call('typeaheadAirport', query, (err, res) ->
        if err or _.isUndefined(res) or _.isEmpty(res)
          return
        else
          callback(res.map( (v) -> {value: v._id + " - " + v.city, label: v._id} ))
      )
    }]
  })
  # Methods to use are:
  #  Template.gritsFilter.arrivalSearch.tokenfield('getTokens')
  #  Template.gritsFilter.arrivalSearch.tokenfield('setTokens', someNewTokenArray)
  #  See: http://sliptree.github.io/bootstrap-tokenfield/#methods
  Template.gritsFilter.arrivalSearch = $('#arrivalSearch').tokenfield({
    typeahead: [null, { source: (query, callback) ->
      Meteor.call('typeaheadAirport', query, (err, res) ->
        if err or _.isUndefined(res) or _.isEmpty(res)
          return
        else
          callback(res.map( (v) -> {value: v._id + " - " + v.city, label: v._id} ))
      )
    }]
  })
  # When the template is rendered, setup a Tracker autorun to listen to changes
  # on isUpdating.  This session reactive var enables/disables, shows/hides the
  # apply button and filterLoading indicator.
  this.autorun ->
    # update the disabled status of the [More] button based loadedRecords
    loadedRecords = Session.get 'grits-net-meteor:loadedRecords'
    totalRecords = Session.get 'grits-net-meteor:totalRecords'
    if loadedRecords < totalRecords
      # disable the [More] button
      $('#loadMore').prop('disabled', false)
    else
      # enable the [More] button
      $('#loadMore').prop('disabled', true)

    # update the ajax-loader
    isUpdating = Session.get 'grits-net-meteor:isUpdating'
    if isUpdating
      $('#applyFilter').prop('disabled', true)
      $('#filterLoading').show()
    else
      $('#applyFilter').prop('disabled', false)
      $('#filterLoading').hide()


# events
#
# Event handlers for the grits_filter.html template
Template.gritsFilter.events
  'keyup #departureSearchMain-tokenfield': (event) ->
    if event.keyCode == 13
      GritsFilterCriteria.scanAll()
      GritsFilterCriteria.apply()
  'click #toggleFilter': (e) ->
    $self = $(e.currentTarget)
    $("#filter").toggle("fast", () ->
      #
    )
  'click #applyFilter': (event, template) ->
    GritsFilterCriteria.scanAll()
    GritsFilterCriteria.apply()
  'click #loadMore': () ->
    Session.set 'grits-net-meteor:lastId',  Template.gritsFilter.getLastFlightId()
  'tokenfield:initialize': (e) ->
    #do not let tokenfields grow beyond their initialized width, this
    #will avoid the filter div expanding horizontally
    $target = $(e.target)
    $container = $target.closest('.tokenized')
    $container.css('max-width',$target.width())
    id = $target.attr('id')
    $('#'+id+'-tokenfield').on('blur', (e) ->
      # only allow tokens
      $container.find('.token-input.tt-input').val("")
    )
  'tokenfield:createtoken': (e) ->
    $target = $(e.target)
    $container = $target.closest('.tokenized')
    tokens = $target.tokenfield('getTokens')
    match = _.find(tokens, (t) -> t.label == e.attrs.label)
    if match
      # do not create a token and clear the input
      $target.closest('.tokenized').find('.token-input.tt-input').val("")
      e.preventDefault()
      return
  'tokenfield:createdtoken': (e) ->
    $target = $(e.target)
    $container = $target.closest('.tokenized')
    tokens = $target.tokenfield('getTokens')
    if tokens.length > 0
      $target.closest('.tokenized').find('.token-input.tt-input').attr('placeholder', '')
  'tokenfield:removedtoken': (e) ->
    $target = $(e.target)
    $container = $target.closest('.tokenized')
    tokens = $target.tokenfield('getTokens')
    if tokens.length == 0
      $target.closest('.tokenized').find('.token-input.tt-input').attr('placeholder', 'Type to search')
