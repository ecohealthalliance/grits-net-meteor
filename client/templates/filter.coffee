Template.filter.events
  'click #toggleFilter': () ->
    self = this
    if $("#filter").length
      $(self).removeClass("fa-minus")
      $(self).addClass("fa-plus")

    $("#filter").toggle("slow")
  'click #applyFilter': () ->
    Meteor.gritsUtil.applyFilters()
    query = Meteor.gritsUtil.getQueryCriteria()
    if _.isUndefined(query) or _.isEmpty(query)
      return
    else
      Session.set 'query', Meteor.gritsUtil.getQueryCriteria()

Template.filter.helpers({
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
    isUpdating = Session.get 'isUpdating'
    if isUpdating
      $('#applyFilter').prop('disabled', true)
      $('#filterLoading').show()
    else
      $('#applyFilter').prop('disabled', false)
      $('#filterLoading').hide()
