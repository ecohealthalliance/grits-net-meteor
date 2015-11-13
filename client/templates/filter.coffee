Template.filter.events
  'click #toggleFilter': (e) ->
    $self = $(e.currentTarget)
    $("#filter").toggle("fast", () ->
      #
    )
  'click #applyFilter': () ->
    #GritsPaths.resetLevels()
    Meteor.gritsUtil.applyFilters()

    query = Meteor.gritsUtil.getQueryCriteria()
    if _.isUndefined(query) or _.isEmpty(query)
      return

    # re-enable the loadMore button when a new filter is applied
    $('#loadMore').prop('disabled', false)

    limit = parseInt($('#limit').val(), 10)
    if !_.isNaN(limit)
      Session.set 'limit', limit
    else
      Session.set 'limit', null
    Session.set 'lastId', null
    Session.set 'query', Meteor.gritsUtil.getQueryCriteria()
  'click #loadMore': () ->
    Session.set 'lastId',  Meteor.gritsUtil.getLastFlightId()
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

Template.filter.helpers({
  loadedRecords: () ->
    return Session.get 'loadedRecords'
  totalRecords: () ->
    return Session.get 'totalRecords'
})

Template.filter.onRendered ->

  # Methods to use are:
  #  Template.filter.departureSearch.tokenfield('getTokens')
  #  Template.filter.departureSearch.tokenfield('setTokens', someNewTokenArray)
  #  See: http://sliptree.github.io/bootstrap-tokenfield/#methods
  Template.filter.departureSearch = $('#departureSearch').tokenfield({
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
  #  Template.filter.arrivalSearch.tokenfield('getTokens')
  #  Template.filter.arrivalSearch.tokenfield('setTokens', someNewTokenArray)
  #  See: http://sliptree.github.io/bootstrap-tokenfield/#methods
  Template.filter.arrivalSearch = $('#arrivalSearch').tokenfield({
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
    loadedRecords = Session.get 'loadedRecords'
    totalRecords = Session.get 'totalRecords'
    if loadedRecords < totalRecords
      # disable the [More] button
      $('#loadMore').prop('disabled', false)
    else
      # enable the [More] button
      $('#loadMore').prop('disabled', true)

    # update the ajax-loader
    isUpdating = Session.get 'isUpdating'
    if isUpdating
      $('#applyFilter').prop('disabled', true)
      $('#filterLoading').show()
    else
      $('#applyFilter').prop('disabled', false)
      $('#filterLoading').hide()
