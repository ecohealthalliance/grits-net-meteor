Meteor.startup ->
  Session.set 'grits-net-meteor:isUpdating', false
  Session.set 'grits-net-meteor:loadedRecords', 0
  Session.set 'grits-net-meteor:totalRecords', 0  
  Session.set 'grits-net-meteor:isReady', false # the map will not be displayed until isReady is set to true
  
  # string externalization/i18n
  Template.registerHelper('_', i18n.get)
  i18n.addLanguage('en', 'English')
  i18n.loadAll(() ->
    i18n.setLanguage('en')
    Session.set 'grits-net-meteor:isReady', true
  )
  