# Template.gritsFilter
#
# When another meteor app adds grits:grits-net-meteor as a package
# Template.gritsFilter will be available globally.
_init = true # flag, set to false when initialization is done
_initStartDate = null # onCreated will initialize the date through GritsFilterCriteria
_initEndDate = null # onCreated will initialize the date through GritsFilterCriteria
_initLimit = null # onCreated will initialize the limt through GritsFilterCriteria
_initLevels = null # onCreated will initialize the limt through GritsFilterCriteria
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
# Unfortunately we need to result to jQuery as twitter's typeahead plugin does
# not allow us to pass in a custom context to the footer.  <%= obj.query %> and
# <%= obj.isEmpty %> are the only things available.
_typeaheadFooter = _.template('
  <div class="airport-footer">
    <div class="row">
      <div class="col-xs-6 pull-middle">
        <span id="suggestionCount"></span>
      </div>
      <div class="col-xs-6 pull-middle">
        <ul class="pager">
          <li class="previous-suggestions">
            <a href="#" id="previousSuggestions">Previous</a>
          </li>
          <li class="next-suggestions">
            <a href="#" id="forwardSuggestions">Forward</a>
          </li>
        </ul>
      </div>
    </div>
  </div>')

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

# returns the datetime picker object for the '#effectiveDate' input  with the label 'End'
#
# @see http://eonasdan.github.io/bootstrap-datetimepicker/Functions/
# @return [Object] datetimePicker object
getEffectiveDatePicker = () ->
  return _effectiveDatePicker

# sets the datetime picker object for the '#effectiveDate' input with the label 'End'
_setEffectiveDatePicker = (datetimePicker) ->
  _effectiveDatePicker = datetimePicker
  return

# returns the datetime picker object for the '#discontinuedDate' input with the label 'Start'
#
# @see http://eonasdan.github.io/bootstrap-datetimepicker/Functions/
# @return [Object] datetimePicker object
getDiscontinuedDatePicker = () ->
  return _discontinuedDatePicker

# sets the datetime picker object for the '#discontinuedDate' input with the label 'Start'
_setDiscontinuedDatePicker = (datetimePicker) ->
  _discontinuedDatePicker = datetimePicker
  return

# determines which field was matched by the typeahead into the server response
#
# @param [String] input, the string used as the search
# @param [Array] results, the server response
# @return [Array] array of matches, with all properties of the model to be available in the suggestion template under the key 'raw'.
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
    typeaheadMatcher = Airport.typeaheadMatcher()
    for field, matcher of typeaheadMatcher
      regex = new RegExp(matcher.regexSearch({search: input}), matcher.regexOptions)
      value = obj[field]
      # cannot match on an empty value
      if _.isEmpty(value)
        continue
      # apply the regex to the value
      if value.match(regex) != null
        # determine if its a previous match
        match = _.find(matches, (m) -> m.label == obj._id)
        # if not, create a new object and assign the properties
        # note: prefix is added to avoid possible confict with the class fields
        # that are extended.
        if _.isUndefined(match)
          match =
            label: obj._id
            value: value
            field: field
            weight: matcher.weight
            display: matcher.display
            raw: obj
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
  start: () ->
    return _initStartDate
  end: () ->
    return _initEndDate
  levels: () ->
    if _init
      # set inital level
      return _initLevels
    else
      # reactive var
      return GritsFilterCriteria.levels.get()
  limit: () ->
    if _init
      # set inital limit
      return _initLimit
    else
      # reactive var
      return GritsFilterCriteria.limit.get()
  stops: () ->
    # reactive var
    obj = GritsFilterCriteria.stops.get()
    if _.isNull(obj)
      return ''
    else
      return obj.value
  seats: () ->
    # reactive var
    obj = GritsFilterCriteria.seats.get()
    if _.isNull(obj)
      return ''
    else
      return obj.value
  weeklyFrequency: () ->
    # reactive var
    obj = GritsFilterCriteria.weeklyFrequency.get()
    if _.isNull(obj)
      return ''
    else
      return obj.value
})

Template.gritsFilter.onCreated ->
  _initStartDate = GritsFilterCriteria.initStart()
  _initEndDate = GritsFilterCriteria.initEnd()
  _initLimit = GritsFilterCriteria.initLimit()
  _initLevels = GritsFilterCriteria.initLevels()
  _init = false # done initializing initial input values

  # Public API
  # Currently we declare methods above for documentation purposes then assign
  # to the Template.gritsFilter as a global export
  Template.gritsFilter.getOrigin = getOrigin
  Template.gritsFilter.getDepartureSearchMain = getDepartureSearchMain
  Template.gritsFilter.getDepartureSearch = getDepartureSearch
  Template.gritsFilter.getArrivalSearch = getArrivalSearch
  Template.gritsFilter.getEffectiveDatePicker = getEffectiveDatePicker
  Template.gritsFilter.getDiscontinuedDatePicker = getDiscontinuedDatePicker

# triggered when the 'filter' template is rendered
Template.gritsFilter.onRendered ->
  _matchSkip = null
  _suggestionGenerator = (query, skip, callback) ->
    _matchSkip = skip
    Meteor.call('typeaheadAirport', query, skip, (err, res) ->
      if err or _.isUndefined(res) or _.isEmpty(res)
        callback([])
        return
      Meteor.call('countTypeaheadAirports', query, (err, count) ->
        matches = _determineFieldMatchesByWeight(query, res)
        # expects an array of objects with keys [label, value]
        callback(matches)

        # keep going to update the _typeaheadFooter via jQuery
        # update the record count
        if count > 1
          if (_matchSkip + 10) > count
            diff = (_matchSkip + 10) - count
            $('#suggestionCount').html("<span>Matches #{_matchSkip+1}-#{_matchSkip+(10-diff)} of #{count}</span>")
          else
            $('#suggestionCount').html("<span>Matches #{_matchSkip+1}-#{_matchSkip+10} of #{count}</span>")
        else if count == 1
          $('#suggestionCount').html("<span>#{count} match found</span>")
        else
          $('#suggestionCount').html("<span>No matches found</span>")

        # enable/disable the pager elements
        if count <= 10
          $('.next-suggestions').addClass('disabled')
          $('.previous-suggestions').addClass('disabled')
        if count > 10
          # edge case min
          if _matchSkip == 0
            $('.previous-suggestions').addClass('disabled')
          # edge case max
          if (count - _matchSkip) <= 10
            $('.next-suggestions').addClass('disabled')

        # bind click handlers
        if !$('.previous-suggestions').hasClass('disabled')
          $('#previousSuggestions').bind('click', (e) ->
            e.preventDefault()
            e.stopPropagation()
            if count <= 10 || _matchSkip <= 10
              _matchSkip = 0
            else
              _matchSkip -= 10
            _suggestionGenerator(query, _matchSkip, callback)
          )
        if !$('.next-suggestions').hasClass('disabled')
          $('#forwardSuggestions').bind('click', (e) ->
            e.preventDefault()
            e.stopPropagation()
            if count <= 10
              _matchSkip 0
            else
              _matchSkip += 10
            _suggestionGenerator(query, _matchSkip, callback)
            return
          )
        return
      )
      return
    )
    return

  departureSearchMain = $('#departureSearchMain').tokenfield({
    typeahead: [{hint:false, highlight: true}, {
      display: (match) ->
        if _.isUndefined(match)
          return
        return match.label
      templates:
        suggestion: _suggestionTemplate
        footer: _typeaheadFooter
      source: (query, callback) ->
        _suggestionGenerator(query, 0, callback)
        return
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
  )

  # set the original state of the filter on document ready
  GritsFilterCriteria.setState()

  # When the template is rendered, setup a Tracker autorun to listen to changes
  # on isUpdating.  This session reactive var enables/disables, shows/hides the
  # apply button and filterLoading indicator.
  this.autorun ->
    # update the disabled status of the [More] button based loadedRecords
    loadedRecords = Session.get 'grits-net-meteor:loadedRecords'
    totalRecords = Session.get 'grits-net-meteor:totalRecords'
    if loadedRecords < totalRecords
      # enable the [More] button when loaded is less than total
      $('#loadMore').prop('disabled', false)
    else
      # disable the [More] button
      $('#loadMore').prop('disabled', true)

    # update the ajax-loader
    isUpdating = Session.get 'grits-net-meteor:isUpdating'
    if isUpdating
      $('#applyFilter').prop('disabled', true)
      $('#filterLoading').show()
    else
      $('#applyFilter').prop('disabled', false)
      $('#filterLoading').hide()
    $("#pathsTable").trigger('update');
    $("#nodesTable").trigger('update');
    $("#heatmapTable").trigger('update');

_changeWeeklyFrequencyHandler = (e) ->
    val = parseInt($("#weeklyFrequencyInput").val(), 10)
    if _.isNaN(val)
      val = null
    op = $('#weeklyFrequencyOperator').val()
    GritsFilterCriteria.weeklyFrequency.set({'value': val, 'operator': op})
    return
_changeStopsHandler = (e) ->
  val = parseInt($("#stopsInput").val(), 10)
  if _.isNaN(val)
    val = null
  op = $('#stopsOperator').val()
  GritsFilterCriteria.stops.set({'value': val, 'operator': op})
  return
_changeSeatsHandler = (e) ->
  val = parseInt($("#seatsInput").val(), 10)
  if _.isNaN(val)
    val = null
  op = $('#seatsOperator').val()
  GritsFilterCriteria.seats.set({'value': val, 'operator': op})
  return
_changeDepartureHandler = (e) ->
  combined = []
  tokens =  _departureSearchMain.tokenfield('getTokens')
  codes = _.pluck(tokens, 'label')
  combined = _.union(codes, combined)
  tokens =  _departureSearch.tokenfield('getTokens')
  codes = _.pluck(tokens, 'label')
  combined = _.union(codes, combined)
  if _.isEqual(combined, GritsFilterCriteria.departures.get())
    # do nothing
    return
  GritsFilterCriteria.departures.set(combined)
  return
_changeArrivalHandler = (e) ->
  tokens =  _arrivalSearch.tokenfield('getTokens')
  codes = _.pluck(tokens, 'label')
  if _.isEqual(codes, GritsFilterCriteria.arrivals.get())
    # do nothing
    return
  GritsFilterCriteria.arrivals.set(codes)
  return
_changeDateHandler = (e) ->
  $target = $(e.target)
  id = $target.attr('id')
  if id == 'discontinuedDate'
    if _.isNull(_discontinuedDatePicker)
      return
    date = _discontinuedDatePicker.data('DateTimePicker').date()
    GritsFilterCriteria.operatingDateRangeStart.set(date)
    return
  if id == 'effectiveDate'
    if _.isNull(_effectiveDatePicker)
      return
    date = _effectiveDatePicker.data('DateTimePicker').date()
    GritsFilterCriteria.operatingDateRangeEnd.set(date)
    return
_changeLevelsHandler = (e) ->
  val = $("#connectednessLevels").val()
  GritsFilterCriteria.levels.set(val)
  return
_changeLimitHandler = (e) ->
  val = $("#limit").val()
  GritsFilterCriteria.limit.set(val)
  return
# events
#
# Event handlers for the grits_filter.html template
Template.gritsSearch.events
  'change #departureSearchMain': _changeDepartureHandler
  'keyup #departureSearchMain-tokenfield': (event) ->
    if event.keyCode == 13
      if GritsFilterCriteria.departures.get() <= 0
        # do not apply without any departures
        return
      GritsFilterCriteria.apply()
    return
Template.gritsFilter.events
  'change #weeklyFrequencyInput': _changeWeeklyFrequencyHandler
  'change #weeklyFrequencyOperator': _changeWeeklyFrequencyHandler
  'change #stopsInput': _changeStopsHandler
  'change #stopsOperator': _changeStopsHandler
  'change #seatsInput': _changeSeatsHandler
  'change #seatsOperator': _changeSeatsHandler
  'change #departureSearch': _changeDepartureHandler
  'change #arrivalSearch': _changeArrivalHandler
  'change #connectednessLevels': _changeLevelsHandler
  'change #limit': _changeLimitHandler
  'dp.change': _changeDateHandler
  'dp.show': (event) ->
    # in order to not be contained within the scrolling div, the style of the
    # .bootstrap-datetimepicker-widget.dropdown-menu is set to fixed then we
    # position it manually below.
    $datetimepicker = $(event.target)
    height = $datetimepicker.height()
    top = $datetimepicker.offset().top
    left = $datetimepicker.offset().left
    $('.bootstrap-datetimepicker-widget.dropdown-menu').css({top: top + height, left: left})
    return
  'click #includeNearbyAirports': (event) ->
    miles = parseInt($("#includeNearbyAirportsRadius").val(), 10)
    departures = GritsFilterCriteria.departures.get()

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
    return
  'click #toggleFilter': (e) ->
    $self = $(e.currentTarget)
    $("#filter").toggle("fast")
    return
  'click #applyFilter': (event, template) ->
    GritsFilterCriteria.apply()
    return
  'click #loadMore': () ->
    GritsFilterCriteria.setOffset()
    return
  'tokenfield:initialize': (e) ->
    $target = $(e.target)
    $container = $target.closest('.tokenized')
    #the typeahead menu should be as wide as the filter at a minimum
    $menu = $container.find('.tt-dropdown-menu')
    $menu.css('min-width', $('#filter').width())
    id = $target.attr('id')
    $('#'+id+'-tokenfield').on('blur', (e) ->
      # only allow tokens
      $container.find('.token-input.tt-input').val("")
    )
    return
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
