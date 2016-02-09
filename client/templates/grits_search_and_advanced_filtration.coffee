# Template.gritsSearchAndAdvancedFiltration
#
# When another meteor app adds grits:grits-net-meteor as a package
# Template.gritsSearchAndAdvancedFiltration will be available globally.
_levelsStartVal = "1"
_seatsStartVal = [0,900]
_stopsStartVal = [0,5]
_wfStartVal = 1
_init = true # flag, set to false when initialization is done
_initStartDate = null # onCreated will initialize the date through GritsFilterCriteria
_initEndDate = null # onCreated will initialize the date through GritsFilterCriteria
_initLimit = null # onCreated will initialize the limt through GritsFilterCriteria
_initLevels = null # onCreated will initialize the limt through GritsFilterCriteria
_departureSearchMain = null # onRendered will set this to a typeahead object
_effectiveDatePicker = null # onRendered will set this to a datetime picker object
_discontinuedDatePicker = null # onRendered will set this to a datetime picker object
_sharedTokens = [] # container for tokens that are shared from departureSearchMain input
_simulationProgress = new ReactiveVar(0);
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

# resets the simuationProgress
resetSimulationProgress = () ->
  _simulationProgress.set(0)
  return

# update the simulationProgress bar
_updateSimulationProgress = (progress) ->
  $('#simulationProgress').css({width: progress})
  return progress

# sets an object to be used by Meteors' Blaze templating engine (views)
Template.gritsSearchAndAdvancedFiltration.helpers({
  simulationProgress: () ->
    progress = _simulationProgress.get() + '%'
    return _updateSimulationProgress(progress)
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

Template.gritsSearchAndAdvancedFiltration.onCreated ->
  _initStartDate = GritsFilterCriteria.initStart()
  _initEndDate = GritsFilterCriteria.initEnd()
  _initLimit = GritsFilterCriteria.initLimit()
  _initLevels = GritsFilterCriteria.initLevels()
  _init = false # done initializing initial input values

  # Public API
  # Currently we declare methods above for documentation purposes then assign
  # to the Template.gritsSearchAndAdvancedFiltration as a global export
  Template.gritsSearchAndAdvancedFiltration.getOrigin = getOrigin
  Template.gritsSearchAndAdvancedFiltration.getDepartureSearchMain = getDepartureSearchMain
  Template.gritsSearchAndAdvancedFiltration.getEffectiveDatePicker = getEffectiveDatePicker
  Template.gritsSearchAndAdvancedFiltration.getDiscontinuedDatePicker = getDiscontinuedDatePicker
  Template.gritsSearchAndAdvancedFiltration.resetSimulationProgress = resetSimulationProgress

# triggered when the 'filter' template is rendered
Template.gritsSearchAndAdvancedFiltration.onRendered ->
  _matchSkip = null
  _suggestionGenerator = (query, skip, callback) ->
    _matchSkip = skip
    Meteor.call('typeaheadAirport', query, skip, (err, res) ->
      Meteor.call('countTypeaheadAirports', query, (err, count) ->

        if res.length > 0
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
          $('.tt-suggestions').empty()
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
    typeahead: [{hint: false, highlight: true}, {
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

  # Toast notification options
  toastr.options = {
    positionClass: 'toast-bottom-center',
    preventDuplicates: true,
  }

  # set the effectiveDatePicker and options
  # Note: Meteor.gritsUtil.effectiveDateMinMax is set in startup.coffee
  options = {
    format: 'MM/DD/YY'
    minDate: Meteor.gritsUtil.effectiveDateMinMax[0],
    maxDate: Meteor.gritsUtil.effectiveDateMinMax[1]
  }
  effectiveDatePicker = $('#effectiveDate').datetimepicker(options)
  _setEffectiveDatePicker(effectiveDatePicker)


  # set the discontinuedDatePicker and options
  # Note: Meteor.gritsUtil.discontinuedDateMinMax is set in startup.coffee
  options = {
    format: 'MM/DD/YY'
    minDate: Meteor.gritsUtil.discontinuedDateMinMax[0],
    maxDate: Meteor.gritsUtil.discontinuedDateMinMax[1]
  }
  discontinuedDatePicker = $('#discontinuedDate').datetimepicker(options)
  _setDiscontinuedDatePicker(discontinuedDatePicker)

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
    # do not show the filter spinner if the overlay isLoading
    if isUpdating && !Template.gritsOverlay.isLoading()
      $('#applyFilter').prop('disabled', true)
      $('#filterLoading').show()
    else
      $('#applyFilter').prop('disabled', false)
      $('#filterLoading').hide()

_changeWeeklyFrequencyHandler = (e) ->
  val = parseInt($("#weeklyFrequencyInputSlider").val(), 10)
  if val isnt _wfStartVal
    _wfStartVal = val
    $('#filterLoading').show()
    if _.isNaN(val)
      val = null
    $('#weeklyFrequencySliderValIndicator').empty().html(val)
    op = '$lte'
    GritsFilterCriteria.weeklyFrequency.set({'value': val, 'operator': op})
  return
_changeSimulatedPassengersHandler = (e) ->
  val = parseInt($("#simulatedPassengersInputSlider").val(), 10)
  if val isnt _wfStartVal
    _wfStartVal = val
    if _.isNaN(val)
      val = null
    $('#simulatedPassengersInputSliderValIndicator').empty().html(val)
  return
_changeStopsSliderHandler = (e) ->
  val = $("#stopsInputSlider").val().split(',')
  val[0] = parseInt(val[0], 10)
  val[1] = parseInt(val[1], 10)
  if val[0] isnt _stopsStartVal[0] or val[1] isnt _stopsStartVal[1]
    _stopsStartVal = val
    $('#filterLoading').show()
    $('#stopsSliderValIndicator').empty().html(val[0] + " : " + val[1])
    if _.isNaN(val[0]) || _.isNaN(val[1])
      val = null
    GritsFilterCriteria.stops.set({'value': val[0], 'operator': '$gte', 'value2': val[1], 'operator2': '$lte'})
  return
_changeSeatsSliderHandler = (e) ->
  val = $("#seatsInputSlider").val().split(',')
  val[0] = parseInt(val[0], 10)
  val[1] = parseInt(val[1], 10)
  if val[0] isnt _seatsStartVal[0] or val[1] isnt _seatsStartVal[1]
    _seatsStartVal = val
    $('#filterLoading').show()
    $('#seatsSliderValIndicator').empty().html(val[0] + " : " + val[1])
    if _.isNaN(val[0]) || _.isNaN(val[1])
      val = null
    GritsFilterCriteria.seats.set({'value': val[0], 'operator': '$gte', 'value2': val[1], 'operator2': '$lte'})
  return
_changeDepartureHandler = (e) ->
  combined = []
  tokens =  _departureSearchMain.tokenfield('getTokens')
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
  val = $("#levelsInputSlider").val()
  if val isnt _levelsStartVal
    _levelsStartVal = val
    $('#filterLoading').show()
    $('#levelsSliderValIndicator').empty().html(val)
    GritsFilterCriteria.levels.set(val)
  return
_changeLimitHandler = (e) ->
  val = $("#limit").val()
  GritsFilterCriteria.limit.set(val)
  return
_setWFStartVal = (e) ->
  _startVal = $("#weeklyFrequencyInputSlider").val().split(',')
# _setStopsStartVal = (e) ->
#   _startVal = $("#stopsInputSlider").val().split(',')
_setSeatsStartVal = (e) ->
  _startVal = $("#seatsInputSlider").val().split(',')
_setLevelsStartVal = (e) ->
  _startVal = $("#levelsInputSlider").val()
_startSimulation = (e) ->
  simPas = parseInt($('#simulatedPassengersInputSlider').slider('getValue'), 10)
  startDate = _discontinuedDatePicker.data('DateTimePicker').date().format("DD/MM/YYYY")
  endDate = _effectiveDatePicker.data('DateTimePicker').date().format("DD/MM/YYYY")
  departures = GritsFilterCriteria.departures.get()
  if departures.length == 0
    toastr.error('The simulator requires at least one Departure')
    return
  origin = departures[0]
  Promise.all([
    new Promise (resolve, reject)->
      Meteor.call('airportLocations', (err, res)->
        if err then return reject(err)
        resolve(res)
      )
    new Promise (resolve, reject)->
      Meteor.call('startSimulation', simPas, startDate, endDate, origin, (err, res) ->
        if err then return reject(err)
        resolve(res)
      )
  ])
  .catch (err)->
    Meteor.gritsUtil.errorHandler(err)
    console.error err
  .then ([airportToCoordinates, res])->
    if res.hasOwnProperty('error')
      Meteor.gritsUtil.errorHandler(res)
      console.error(res)
      return

    # let the user know the simulation started
    _simulationProgress.set(1)

    #Session.set('grits-net-meteor:simulationId', res.simId)
    #$("#sidebar-flightData-tab a")[0].click()

    nodeLayer = Template.gritsMap.getInstance().getGritsLayer('Nodes')
    pathLayer = Template.gritsMap.getInstance().getGritsLayer('Paths')
    nodeLayer.clear()
    pathLayer.clear()

    loaded = 0
    
    airportCounts = {}
    itinCount = 0
    _updateHeatmap = _.throttle(->
      Heatmaps.remove({})
      # map the airportCounts object to one with percentage values
      airportPercentages = _.object([key, val / itinCount] for key, val of airportCounts)
      # key the heatmap to the departure airports so it can be filtered
      # out if the query changes.
      airportPercentages._id = departures.sort().join("")
      Heatmap.createFromDoc(airportPercentages, airportToCoordinates)
    , 500)
    Meteor.subscribe('SimulationItineraries', res.simId)
    Itineraries.find({'simulationId':res.simId}).observeChanges({
      added: (id, fields) ->
        itinCount++
        if airportCounts[fields.destination]
          airportCounts[fields.destination]++
        else
          airportCounts[fields.destination] = 1
        loaded += 1
        nodes = nodeLayer.convertItineraries(fields, origin)
        if nodes[0] == null || nodes[1] == null
          return
        pathLayer.convertItineraries(fields, nodes[0], nodes[1])

        # update the simulatorProgress bar
        if simPas > 0
          progress = Math.ceil((loaded/simPas) * 100)
          _simulationProgress.set(progress)

        if loaded == simPas
          #finaldraw
          _simulationProgress.set(100)
          nodeLayer.draw()
          pathLayer.draw()
          _updateHeatmap()
        else
          _updateHeatmap()
          _debouncedDraw(nodeLayer, pathLayer)
    })

_debouncedDraw = _.debounce((nodeLayer, pathLayer) ->
  nodeLayer.draw()
  pathLayer.draw()
, 250)

# events
#
# Event handlers for the grits_filter.html template
Template.gritsSearchAndAdvancedFiltration.events
  'slideStop #weeklyFrequencyInputSlider': _changeWeeklyFrequencyHandler
  'slideStop #simulatedPassengersInputSlider': _changeSimulatedPassengersHandler
  'slideStop #stopsInputSlider': _changeStopsSliderHandler
  'slideStop #seatsInputSlider': _changeSeatsSliderHandler
  'slideStop #levelsInputSlider': _changeLevelsHandler
  'slideStart #weeklyFrequencyInputSlider': _setWFStartVal
  #'slideStart #stopsInputSlider': _setStopsStartVal
  'slideStart #seatsInputSlider': _setSeatsStartVal
  'slideStart #levelsInputSlider': _setLevelsStartVal
  'click #startSimulation': _startSimulation
  'change #departureSearch': _changeDepartureHandler
  'change #arrivalSearch': _changeArrivalHandler
  'change #limit': _changeLimitHandler
  'change #departureSearchMain': _changeDepartureHandler
  'keyup #departureSearchMain-tokenfield': (event) ->
    if event.keyCode == 13
      if GritsFilterCriteria.departures.get() <= 0
        # do not apply without any departures
        return
      GritsFilterCriteria.apply()
    return
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

    if (departures[0].indexOf(GritsMetaNode.PREFIX) >= 0)
      toastr.error('Include Nearby does not work with MetaNodes')
      return false

    if $('#includeNearbyAirports').is(':checked')
      Session.set('grits-net-meteor:isUpdating', true)
      Meteor.call('findNearbyAirports', departures[0], miles, (err, airports) ->
        if err
          Meteor.gritsUtil.errorHandler(err)
          return

        nearbyTokens = _.pluck(airports, '_id')
        union = _.union(_sharedTokens, nearbyTokens)
        _departureSearchMain.tokenfield('setTokens', union)
        Session.set('grits-net-meteor:isUpdating', false)
      )
    else
      departureSearch = getDepartureSearchMain()
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
    $container.find('.tt-dropdown-menu').css('z-index', 999999)
    $container.find('.token-input.tt-input').css('height', '30px')
    $container.find('.token-input.tt-input').css('font-size', '20px')
    $container.find('.tokenized.main').prepend($("#searchIcon"))
    $('#' + id + '-tokenfield').on('blur', (e) ->
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
    token = e.attrs.label
    return false
  'tokenfield:removedtoken': (e) ->
    $target = $(e.target)
    tokens = $target.tokenfield('getTokens')
    # determine if the remaining tokens is empty, then show the placeholder text
    if tokens.length == 0
      if $target.attr('id') in ['departureSearch', 'departureSearchMain']
        $('#includeNearbyAirports').prop('checked', false)

    token = e.attrs.label
    return false
