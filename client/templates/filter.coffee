Template.filter.events
  'click #toggleFilter': (e) ->
    $self = $(e.currentTarget)
    $("#filter").toggle("slow", () ->
      if $("#filter :visible").length == 0
        $self.removeClass('fa-minus').addClass("fa-plus")
      else
        $self.removeClass('fa-plus').addClass("fa-minus")
    )
  'click #applyFilter': () ->
    #L.MapNodes.setCurrentOrigin(false)
    GritsPaths.resetLevels()
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


Template.filter.helpers({
  loadedRecords: () ->
    return Session.get 'loadedRecords'
  totalRecords: () ->
    return Session.get 'totalRecords'
  # departureAirports is the helper for autocompletion module
  departureAirports: ->
    return {
      position: "top",
      limit: 10,
      rules: [
        {
          token: '!',
          collection: 'Airports',
          subscription: 'autoCompleteAirports',
          field: '_id',
          template: Template.airportPill,
          filter: {
            $and: [
              {'_id': $in: Session.get('previousDepartureAirports') }
            ]
          }
        },
        {
          token: '@',
          collection: 'Airports',
          subscription: 'autoCompleteAirports',
          field: '_id',
          template: Template.airportPill
        },
      ]
    }
  # arrivalAirports is the helper for autocompletion module
  arrivalAirports: ->
    return {
      position: "top",
      limit: 10,
      rules: [
        {
          token: '!',
          collection: 'Airports',
          subscription: 'autoCompleteAirports',
          field: '_id',
          template: Template.airportPill,
          filter: {
            $and: [
              {'_id': $in: Session.get('previousArrivalAirports') }
            ]
          }
        },
        {
          token: '@',
          collection: 'Airports',
          subscription: 'autoCompleteAirports',
          field: '_id',
          template: Template.airportPill
        },
      ]
    }
})

Template.filter.onRendered ->
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
