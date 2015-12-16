# Template.gritsFilter
#
# When another meteor app adds grits:grits-net-meteor as a package
# Template.gritsFilter will be available globally.

_lastFlightId = null # stores the last flight _id from the collection, used in limit/offset
_departureSearchMain = null # onRendered will set this to a typeahead object
_departureSearch = null # onRendered will set this to a typeahead object
_arrivalSearch = null # onRendered will set this to a typeahead object
_effectiveDatePicker = null # onRendered will set this to a datetime picker object
_discontinuedDatePicker = null # onRendered will set this to a datetime picker object
_sharedTokens = [] # container for tokens that are shared from departureSearchMain input
_suggestionTemplate = _.template('
  <span class="airport-code"><%= raw._id %></span>
  <span class="airport-info">
    <%= raw.name %>
    <% if (display) { %>
      <span class="additional-info">
        <span><%= display %>:</span> <%= value %>
      <span>
    <% } %>
  </span>')

# provides one-way synchroniziation between tokens in departureSearchMain and
# departureSearch when a token is created
#
# @param [String] newToken, a new token label
# @param [String] id, the element id that triggered the tokenfield:createdtoken event
_syncCreatedSharedToken = (newToken, id) ->
  _sharedTokens = _departureSearchMain.tokenfield('getTokens')
  if id == 'departureSearchMain'
    rawTokens = _departureSearch.tokenfield('getTokens')
    tokens = _.pluck(rawTokens, 'label')
    if _.indexOf(tokens, newToken) >= 0
      _sharedTokens = tokens
    else
      _sharedTokens = _.union(tokens, [newToken])
      _departureSearch.tokenfield('createToken', newToken)
  return

# provides one-way synchroniziation between tokens in departureSearchMain and
# departureSearch when a token is removed
#
# @param [String] newToken, a new token label
# @param [String] id, the element id that triggered the tokenfield:removetoken event
_syncRemovedSharedToken = (newToken, id) ->
  _sharedTokens = _departureSearchMain.tokenfield('getTokens')
  if id == 'departureSearchMain'
    rawTokens = _departureSearch.tokenfield('getTokens')
    tokens = _.pluck(rawTokens, 'label')
    if _.indexOf(tokens, newToken) < 0
      return
    else
      tokens.splice(_.indexOf(tokens, newToken), 1)      
      _departureSearch.tokenfield('setTokens', tokens)
  return

# returns the last flight _id, used for the [More] button in limit/offset
#
# @return [String] lastFlightId, the last _id of a flight record
getLastFlightId = () ->
  _lastFlightId

# sets the last flight _id
#
# @param [String] lastId, the last _id of a flight record
setLastFlightId = (lastId) ->
  if _.isUndefined(lastId)
    return
  _lastFlightId = lastId


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

# returns the datetime picker object for the '#fodStart' input
#
# @see http://eonasdan.github.io/bootstrap-datetimepicker/Functions/
# @return [Object] datetimePicker object
getEffectiveDatePicker = () ->
  return _effectiveDatePicker

# sets the datetime picker object for the '#fodStart' input
_setEffectiveDatePicker = (datetimePicker) ->
  _effectiveDatePicker = datetimePicker
  return

# returns the datetime picker object for the '#fodStart' input
#
# @see http://eonasdan.github.io/bootstrap-datetimepicker/Functions/
# @return [Object] datetimePicker object
getDiscontinuedDatePicker = () ->
  return _discontinuedDatePicker

# sets the datetime picker object for the '#fodStart' input
_setDiscontinuedDatePicker = (datetimePicker) ->
  _discontinuedDatePicker = datetimePicker
  return

# determines which field was matched by the typeahead into the server response
#
# @param [String] input, the string used as the search
# @param [Array] results, the server response
# @return [Array] array of matches, extends the raw document of the base Astro class.  This allows all properties of the model to be available in the suggestion template.
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
  for obj in res
    # get the typeahead matcher from the Astro Class, contains weight, display
    # and regexOptions
    typeaheadMatcher = obj.typeaheadMatcher()
    # get the raw document from Astro, this will also be used for the
    # _suggestionTemplate
    object = _.extend(obj.raw()) 
    for field, matcher of typeaheadMatcher
      regex = new RegExp(input, matcher.regexOptions)
      value = object[field]
      # cannot match on an empty value
      if _.isEmpty(value)
        continue
      # apply the regex to the value
      if value.match(regex) != null
        # determine if its a previous match
        match = _.find(matches, (m) -> m.label == object._id)
        # if not, create a new object and assign the properties
        # note: prefix is added to avoid possible confict with the class fields
        # that are extended.
        if _.isUndefined(match)
          match =
            label: object._id
            value: value
            field: field
            weight: matcher.weight
            display: matcher.display
            raw: object
          matches.push(match)
          continue
        else
          # Previous match exists, update the values if its of heigher weight
          if matcher.weight > match.weight
            match.value = value
            match.field = field
            match.weight = matcher.weight
            match.display = matcher.display   
  if Meteor.gritsUtil.debug
    console.log('matches:', matches)
  if matches.length > 0
    return matches.sort(compare)
  return matches

# sets an object to be used by Meteors' Blaze templating engine (views)
Template.gritsFilter.helpers({
  loadedRecords: () ->
    return Session.get 'grits-net-meteor:loadedRecords'
  totalRecords: () ->
    return Session.get 'grits-net-meteor:totalRecords'
  state: () ->
    # GritsFilterCriteria.stateChanged is a reactive-var
    state = GritsFilterCriteria.stateChanged.get()
    if _.isNull(state)
      return
    if state
      return true
    else
      return false
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
  Template.gritsFilter.getEffectiveDatePicker = getEffectiveDatePicker
  Template.gritsFilter.getDiscontinuedDatePicker = getDiscontinuedDatePicker

# triggered when the 'filter' template is rendered
Template.gritsFilter.onRendered ->
  departureSearchMain = $('#departureSearchMain').tokenfield({
    typeahead: [{hint:false, highlight:true}, {
      display: (match) ->
        if _.isUndefined(match)
          return
        return match.label
      templates:
        suggestion: _suggestionTemplate
      source: (query, callback) ->
        Meteor.call('typeaheadAirport', query, (err, res) ->
          if err or _.isUndefined(res) or _.isEmpty(res)
            return
          matches = _determineFieldMatchesByWeight(query, res)
          # expects an array of objects with keys [label, value]
          callback(matches)
      )
    }]
  })
  _setDepartureSearchMain(departureSearchMain)

  departureSearch = $('#departureSearch').tokenfield({})
  _setDepartureSearch(departureSearch)

  arrivalSearch = $('#arrivalSearch').tokenfield({})
  _setArrivalSearch(arrivalSearch)
  
  # Toast notification options
  toastr.options = {
    positionClass: 'toast-bottom-center',
    preventDuplicates: true,
  }

  # set the effectiveDatePicker and options
  Meteor.call('findMinMaxDateRange', 'effectiveDate', (err, minMax) ->
    if (err)
      Meteor.gritsUtil.errorHandler(err)
      return
    if Meteor.gritsUtil.debug
      console.log('effectiveDate:minMax: ', minMax)
    min = minMax[0]
    max = minMax[1]
    options = {
      format: 'MM/DD/YY'
    }
    if !_.isNull(min)
      options.minDate = min
    if !_.isNull(max)
      options.maxDate = max
    effectiveDatePicker = $('#effectiveDate').datetimepicker(options)
    _setEffectiveDatePicker(effectiveDatePicker)
    $(".bootstrap-datetimepicker-widget table td.day").css('width': '30px')
  )

  # set the discontinuedDatePicker and options
  Meteor.call('findMinMaxDateRange', 'discontinuedDate', (err, minMax) ->
    if (err)
      Meteor.gritsUtil.errorHandler(err)
      return
    if Meteor.gritsUtil.debug
      console.log('discontinuedDate:minMax: ', minMax)
    min = minMax[0]
    max = minMax[1]    
    options = {
      format: 'MM/DD/YY'
    }
    if !_.isNull(min)
      options.minDate = min
    if !_.isNull(max)
      options.maxDate = max    
    discontinuedDatePicker = $('#discontinuedDate').datetimepicker(options)
    _setDiscontinuedDatePicker(discontinuedDatePicker)
    $(".bootstrap-datetimepicker-widget table td.day").css('width': '30px')
  )  
  
  # set the originals state of the filter on document ready
  GritsFilterCriteria.setState()
  
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
  'change .advanced-filter-status': (event) ->
    # compare the state of the filter so that an indicator may be shown to the user
    GritsFilterCriteria.compareStates()
  'dp.change': (event) ->
    # compare the state of the filter so that an indicator may be shown to the user
    GritsFilterCriteria.compareStates()
    return
  'click #includeNearbyAirports': (event) ->
    miles = parseInt($("#includeNearbyAirportsRadius").val(), 10)
    departures = GritsFilterCriteria.readDeparture()
    
    if departures.length <= 0
      toastr.error('Include Nearby requires a Departure')
      return false
    
    if $('#includeNearbyAirports').is(':checked')
      Session.set('grits-net-meteor:isUpdating', true)
      Meteor.call('findNearbyAirports', departures[0], miles, (err, airports) ->
        if err
          Meteor.gritsUtil.errorHandler(err)
          return
        
        nearbyTokens = _.pluck(airports, '_id')
        union = _.union(_sharedTokens, nearbyTokens)              
        _departureSearch.tokenfield('setTokens', union)
        Session.set('grits-net-meteor:isUpdating', false)
      )
    else
      departureSearch = getDepartureSearch()      
      departureSearch.tokenfield('setTokens', _sharedTokens)
  'keyup #departureSearchMain-tokenfield': (event) ->
    if event.keyCode == 13
      if GritsFilterCriteria.readDeparture() <= 0
        # do not apply without any departures
        return
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
    width = parseInt($('#filter').width() *.80, 10)
    $container.css('max-width', width)
    #the typeahead menu should be as wide as the filter at a minimum
    $menu = $container.find('.tt-dropdown-menu')
    $menu.css('min-width', $('#filter').width())
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
    tokens = $target.tokenfield('getTokens')
    # remove the placeholder text
    if tokens.length > 0
      $target.closest('.tokenized').find('.token-input.tt-input').attr('placeholder', '')
    
    token = e.attrs.label
    _syncCreatedSharedToken(token, $target.attr('id'))
    return false
  'tokenfield:removedtoken': (e) ->
    $target = $(e.target)
    tokens = $target.tokenfield('getTokens')        
    # determine if the remaining tokens is empty, then show the placeholder text
    if tokens.length == 0
      $target.closest('.tokenized').find('.token-input.tt-input').attr('placeholder', 'Type to search')
      if $target.attr('id') in ['departureSearch', 'departureSearchMain']
        $('#includeNearbyAirports').prop('checked', false)
    
    token = e.attrs.label
    _syncRemovedSharedToken(token, $target.attr('id'))
    return false
