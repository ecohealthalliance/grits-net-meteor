Meteor.startup ->
  Session.set 'grits-net-meteor:query', null
  Session.set 'grits-net-meteor:isUpdating', false
  Session.set 'grits-net-meteor:loadedRecords', 0
  Session.set 'grits-net-meteor:totalRecords', 0
  Session.set 'grits-net-meteor:limit', null
  Session.set 'grits-net-meteor:level', null
  Session.set 'grits-net-meteor:lastId', null

Meteor.gritsUtil =  
  debug: true