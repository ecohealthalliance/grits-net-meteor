# Template.gritsFilter
#
# When another meteor app adds grits:grits-net-meteor as a package
# Template.gritsFilter will be available globally.

_lastFlightId = null # stores the last flight _id from the collection, used in limit/offset
_departureSearchMain = null # onRendered will set this to a typeahead object
_departureSearch = null # onRendered will set this to a typeahead object
_arrivalSearch = null # onRendered will set this to a typeahead object
_typeaheadWeights =
  _id: 6
  city: 5
  name: 4
  #countryName: 3
  #stateName: 2
  #notes: 1


# returns the last flight _id, used for the [More] button in limit/offset
#
# @return [String] lastFlightId, the last _id of a flight record
getLastFlightId = () ->
  _lastFlightId

# sets the last flight _id
#
# @param [String] lastId, the last _id of a flight record
setLastFlightId = (lastId) ->
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

# returns the first origin within GritsFilterCriteria
#
# @return [String] origin, a string airport IATA code
getOrigin = () ->
  query = GritsFilterCriteria.getQueryObject()
  if _.has(query, 'departureAirport._id')
    # the filter has an array of airports 
    if _.has(query['departureAirport._id'], '$in')
      origins = query['departureAirport._id']['$in']
      if _.isArray(origins) and origins.length > 0
        return origins[0]
  return null

# returns the typeahead object for the '#departureSearchMain' input
#
# @see: http://sliptree.github.io/bootstrap-tokenfield/#methods
# @return [Object] typeahead
getDepartureSearchMain = () ->
  return _departureSearchMain

# sets the typeahead object for the '#departureSearchMain' input
_setDepartureSearchMain = (typeahead) ->
  _departureSearchMain = typeahead
  return

# returns the typeahead object for the '#departureSearch' input
#
# @see http://sliptree.github.io/bootstrap-tokenfield/#methods
# @return [Object] typeahead
getDepartureSearch = () ->
  return _departureSearch

# sets the typeahead object for the '#departureSearch' input
_setDepartureSearch = (typeahead) ->
  _departureSearch = typeahead
  return

# returns the typeahead object for the '#arrivalSearch' input
#
# @see http://sliptree.github.io/bootstrap-tokenfield/#methods
# @return [Object] typeahead
getArrivalSearch = () ->
  return _arrivalSearch

# sets the typeahead object for the '#departureSearchMain' input
_setArrivalSearch = (typeahead) ->
  _arrivalSearch = typeahead
  return

# determines which field was matched by the typeahead into the server response 
#
# @param [String] input, the string used as the search
# @param [Array] results, the server response
_determineFieldMatchesByWeight = (input, res) ->
  numComparator = (a, b) ->
    a - b
  strComparator = (a, b) ->
    if a < b
      return -1
    if a > b
      return 1
    return 0
  compare = (a, b) ->
    return strComparator(a.label, b.label) || numComparator(a.weight, b.weight)
  
  matches = []
  regex = new RegExp(".*?(?:^|\s)(#{input}[^\s$]*).*?", 'ig')
  
  for obj in res
    for field, weight of _typeaheadWeights
      value = obj.get(field)
      if _.isEmpty(value)
        continue
      if value.match(regex) != null
        match = _.find(matches, (m) -> m.label == obj.get('_id'))
        if _.isUndefined(match)
          match =
            label: obj.get('_id')
            value: 'Match: <b>' + field + '</b> &nbsp;&nbsp;' + obj.get('_id') + ' - ' + obj.get('name') + ' - ' + obj.get('city')
            field: field
            city: obj.get('city')
            name: obj.get('name')
            weight: weight
          matches.push(match)
          continue
        else          
          if weight > match.weight
            match.value = obj.get('_id') + ' - ' + value
            match.field = field
            match.weight = weight
  if matches.length > 0
    return matches.sort(compare)
  return matches
  
# sets an object to be used by Meteors' Blaze templating engine (views)
Template.gritsFilter.helpers({
  loadedRecords: () ->
    return Session.get 'grits-net-meteor:loadedRecords'
  totalRecords: () ->
    return Session.get 'grits-net-meteor:totalRecords'
})

Template.gritsFilter.onCreated ->
  # Public API
  # Currently we declare methods above for documentation purposes then assign
  # to the Template.gritsFilter as a global export
  Template.gritsFilter.getLastFlightId = getLastFlightId
  Template.gritsFilter.setLastFlightId = setLastFlightId
  Template.gritsFilter.getOrigin = getOrigin
  Template.gritsFilter.getDepartureSearchMain = getDepartureSearchMain
  Template.gritsFilter.getDepartureSearch = getDepartureSearch
  Template.gritsFilter.getArrivalSearch = getArrivalSearch

# triggered when the 'filter' template is rendered
Template.gritsFilter.onRendered ->  
  departureSearchMain = $('#departureSearchMain').tokenfield({
    typeahead: [null, { source: (query, callback) ->
      Meteor.call('typeaheadAirport', query, (err, res) ->
        if err or _.isUndefined(res) or _.isEmpty(res)
          return
        else
          matches = _determineFieldMatchesByWeight(query, res)
          console.log 'matches: ', matches
          # expects an array of objects with keys [label, value]
          callback(matches)
      )
    }]
  })
  _setDepartureSearchMain(departureSearchMain)
  
  departureSearch = $('#departureSearch').tokenfield({
    typeahead: [null, { source: (query, callback) ->
      Meteor.call('typeaheadAirport', query, (err, res) ->
        if err or _.isUndefined(res) or _.isEmpty(res)
          return
        else
          callback(res.map( (v) -> {value: v._id + " - " + v.city, label: v._id} ))
      )
    }]
  })
  _setDepartureSearch(departureSearch)
  
  arrivalSearch = $('#arrivalSearch').tokenfield({
    typeahead: [null, { source: (query, callback) ->
      Meteor.call('typeaheadAirport', query, (err, res) ->
        if err or _.isUndefined(res) or _.isEmpty(res)
          return
        else
          callback(res.map( (v) -> {value: v._id + " - " + v.city, label: v._id} ))
      )
    }]
  })
  _setArrivalSearch(arrivalSearch)
  
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
