Meteor.gritsUtil =
  debug: true
  errorHandler: (err) ->
    if typeof err != 'undefined'
      if err.hasOwnProperty('message')
        toastr.error(err.message)
      else
        toastr.error(err)
        console.error(err)
    Session.set('grits-net-meteor:isUpdating', false)
    return
