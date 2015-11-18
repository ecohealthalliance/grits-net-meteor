# Template.gritsFilter
#
# When another meteor app adds grits:grits-net-meteor as a package
# Template.gritsFilter will be available globally.
Template.gritsFilter.lastId = null # stores the lastId from the collection, used in limit/offset
Template.gritsFilter.queryCrit = [] # @property [Array<JSON>] containing current query criteria

Template.gritsFilter.getLastFlightId = () ->
  @lastId
Template.gritsFilter.setLastFlightId = () ->
  lastFlight = null
  if Flights.find().count() > 0
    options =
      sort:
        _id: -1
    lastFlight = Flights.find({}, options).fetch()[0];
  if lastFlight
    @lastId = lastFlight._id

Template.gritsFilter.getOrigin = () ->
  query = Template.gritsFilter.getQueryCriteria()
  if _.has(query, 'departureAirport._id')
    # the filter has an array of airports 
    if _.has(query['departureAirport._id'], '$in')
      origins = query['departureAirport._id']['$in']
      if _.isArray(origins) and origins.length > 0
        return origins[0]
  return null

# Get the JSON formatted Meteor.gritsUtil.queryCrit
#
# @return [JSON] JSON formatted Meteor.gritsUtil.queryCrit
Template.gritsFilter.getQueryCriteria = () ->
    jsoo = {}
    for crit in @queryCrit
      jsoo[crit.key] = crit.value
    return jsoo

# Remove query criteria from Meteor.gritsUtil.queryCrit
#
# @param [int] critId - Id of queryCrit to be removed
# @return [JSON] JSON formatted Meteor.gritsUtil.queryCrit
Template.gritsFilter.removeQueryCriteria = (critId) ->
  for crit in @queryCrit
    if _.isEmpty(crit)
      return
    else
      if crit.critId is critId
        @queryCrit.splice(@queryCrit.indexOf(crit), 1)

# Add query criteria to Meteor.gritsUtil.queryCrit
#
# @param [JSON] newQueryCrit - queryCrit to be added to Meteor.gritsUtil.queryCrit
# @return [JSON] JSON formatted Meteor.gritsUtil.queryCrit
Template.gritsFilter.addQueryCriteria = (newQueryCrit) ->
  for crit in @queryCrit
    if crit.critId is newQueryCrit.critId
      @queryCrit.splice(@queryCrit.indexOf(crit), 1)
      @queryCrit.push(newQueryCrit)
      return false #updated
  @queryCrit.push(newQueryCrit)
  return true #added

# applyFilters
#
# Iterate over the filters object then invoke its values.
Template.gritsFilter.applyFilters = () ->  
  for filterName, filterMethod of @filters
    filterMethod()
# filters
#
# Object containing the filter methods
Template.gritsFilter.filters =
  levelFilter: () ->
    val = $("#connectednessLevels").val()
    Template.gritsFilter.removeQueryCriteria(55)
    if val isnt '' and val isnt '0'
      Template.gritsFilter.addQueryCriteria({'critId': 55, 'key': 'flightNumber', 'value': {$ne:-val}})
    return
  # seatsFilter
  #
  # apply a filter on number of seats if it is not undefined or NaN
  seatsFilter: () ->
    value = {}
    val = parseInt($("#seatsInput").val())
    op = $('#seats-operand').val();
    if _.isUndefined(op)
      return
    if _.isUndefined(val) or isNaN(val)
      Template.gritsFilter.removeQueryCriteria(2)
    else
      if op == '$eq'
        value = val
      else
        value[op] = val
      Template.gritsFilter.addQueryCriteria({'critId': 2, 'key': 'totalSeats', 'value': value})
  # applyStopsFilter
  #
  # apply a filter on number of stops if it is not undefined or NaN
  stopsFilter: () ->
    value = {}
    val = parseInt($("#stopsInput").val())
    op = $('#stops-operand').val();
    if _.isUndefined(op)
      return
    if _.isUndefined(val) or isNaN(val)
      Template.gritsFilter.removeQueryCriteria(1)
    else
      if op == '$eq'
        value = val
      else
        value[op] = val
      Template.gritsFilter.addQueryCriteria({'critId': 1, 'key': 'stops', 'value': value})
  # departureSearchFilter
  #
  # apply a filter on the parsed airport codes from the departureSearch input
  # @param [String] str, the airport code
  departureSearchFilter: () ->
    combined = []
    
    if typeof Template.gritsFilter.departureSearchMain != 'undefined'
      tokens =  Template.gritsFilter.departureSearchMain.tokenfield('getTokens')
      codes = _.pluck(tokens, 'label')
      combined = _.union(codes, combined)
    
    if typeof Template.gritsFilter.departureSearch != 'undefined'
      tokens =  Template.gritsFilter.departureSearch.tokenfield('getTokens')
      codes = _.pluck(tokens, 'label')
      combined = _.union(codes, combined)
      
    if _.isEmpty(combined)
      Template.gritsFilter.removeQueryCriteria(11)
    else
      Template.gritsFilter.addQueryCriteria({'critId': 11, 'key': 'departureAirport._id', 'value': {$in: combined}})
        
  # arrivalSearchFilter
  #
  # apply a filter on the parsed airport codes from the arrivalSearch input
  # @param [String] str, the airport code
  arrivalSearchFilter: () ->
    if typeof Template.gritsFilter.departureSearch != 'undefined'
      tokens =  Template.gritsFilter.arrivalSearch.tokenfield('getTokens')
      codes = _.pluck(tokens, 'label')
      if _.isEmpty(codes)
        Template.gritsFilter.removeQueryCriteria(12)
      else
        Template.gritsFilter.addQueryCriteria({'critId': 12, 'key': 'arrivalAirport._id', 'value': {$in: codes}})
        
  daysOfWeekFilter: () ->
    if $('#dowSUN').is(':checked')
      Template.gritsFilter.addQueryCriteria({'critId': 3, 'key': 'day1', 'value': true})
    else if !$('#dowSUN').is(':checked')
      Template.gritsFilter.removeQueryCriteria(3)

    if $('#dowMON').is(':checked')
      Template.gritsFilter.addQueryCriteria({'critId': 4, 'key': 'day2', 'value': true})
    else if !$('#dowMON').is(':checked')
      Template.gritsFilter.removeQueryCriteria(4)

    if $('#dowTUE').is(':checked')
      Template.gritsFilter.addQueryCriteria({'critId': 5, 'key': 'day3', 'value': true})
    else if !$('#dowTUE').is(':checked')
      Template.gritsFilter.removeQueryCriteria(5)

    if $('#dowWED').is(':checked')
      Template.gritsFilter.addQueryCriteria({'critId': 6, 'key': 'day4', 'value': true})
    else if !$('#dowWED').is(':checked')
      Template.gritsFilter.removeQueryCriteria(6)

    if $('#dowTHU').is(':checked')
      Template.gritsFilter.addQueryCriteria({'critId': 7, 'key': 'day5', 'value': true})
    else if !$('#dowTHU').is(':checked')
      Template.gritsFilter.removeQueryCriteria(7)

    if $('#dowFRI').is(':checked')
      Template.gritsFilter.addQueryCriteria({'critId': 8, 'key': 'day6', 'value': true})
    else if !$('#dowFRI').is(':checked')
      Template.gritsFilter.removeQueryCriteria(8)

    if $('#dowSAT').is(':checked')
      Template.gritsFilter.addQueryCriteria({'critId': 9, 'key': 'day7', 'value': true})
    else if !$('#dowSAT').is(':checked')
      Template.gritsFilter.removeQueryCriteria(9)
  weeklyFrequencyFilter: () ->
    value = {}
    val = parseInt($("#weeklyFrequencyInput").val())
    op = $('#weekly-frequency-operand').val();
    if _.isUndefined(op)
      return
    if _.isUndefined(val) or isNaN(val)
      Template.gritsFilter.removeQueryCriteria(10)
    else
      if op == '$eq'
        value = val
      else
        value[op] = val
      Template.gritsFilter.addQueryCriteria({'critId': 10, 'key': 'weeklyFrequency', 'value': value})


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
  # applyFilter button and filterLoading indicator.

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
      $('#applyFilter').click()
  'click #toggleFilter': (e) ->
    $self = $(e.currentTarget)
    $("#filter").toggle("fast", () ->
      #
    )
  'click #applyFilter': (event, template) ->
    Template.gritsFilter.applyFilters()

    query = Template.gritsFilter.getQueryCriteria()
    if _.isUndefined(query) or _.isEmpty(query)
      return

    # re-enable the loadMore button when a new filter is applied
    $('#loadMore').prop('disabled', false)

    limit = parseInt($('#limit').val(), 10)
    if !_.isNaN(limit)
      Session.set 'grits-net-meteor:limit', limit
    else
      Session.set 'grits-net-meteor:limit', null
    Session.set 'grits-net-meteor:lastId', null
    Session.set 'grits-net-meteor:query', Template.gritsFilter.getQueryCriteria()
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
