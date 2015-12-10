Meteor.startup ->
  Session.set 'grits-net-meteor:query', null
  Session.set 'grits-net-meteor:isUpdating', false
  Session.set 'grits-net-meteor:loadedRecords', 0
  Session.set 'grits-net-meteor:totalRecords', 0
  Session.set 'grits-net-meteor:limit', null
  Session.set 'grits-net-meteor:levels', 1
  Session.set 'grits-net-meteor:lastId', null

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
    