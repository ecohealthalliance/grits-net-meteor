Meteor.startup ->
  Session.set 'previousDepartureAirports', []
  Session.set 'previousArrivalAirports', []
  Session.set 'previousFlights', []
  Session.set 'query', {}
  Session.set 'isUpdating', false

@nodeHandler =
  click: (node) ->
    Meteor.gritsUtil.showNodeDetails(node)
    if not Session.get('isUpdating')
      $("#departureSearch").val('!' + node.id);
      $("#applyFilter").click()

@pathHandler =
  click: (path) ->
    Meteor.gritsUtil.showPathDetails(path)

Template.map.onRendered ->
  Meteor.gritsUtil.initWindow('grits-map', {'height': window.innerHeight})
  OpenStreetMap = L.tileLayer('http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    key: '1234'
    layerName: 'OpenStreetMap'
    styleId: 22677)
  MapQuestOpen_OSM = L.tileLayer('http://otile{s}.mqcdn.com/tiles/1.0.0/{type}/{z}/{x}/{y}.{ext}',
    type: 'map'
    layerName: 'MapQuestOpen_OSM'
    ext: 'jpg'
    subdomains: '1234')
  Esri_WorldImagery = L.tileLayer('http://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    layerName: 'Esri_WorldImagery')
  baseLayers = [OpenStreetMap, Esri_WorldImagery, MapQuestOpen_OSM]
  Meteor.gritsUtil.initLeaflet('grits-map', {'zoom': 2,'latlng': [37.8, -92]}, baseLayers)

  # Add the filter to the map's controls.
  Meteor.gritsUtil.addControl('bottomleft', 'info', '<div id="filterContainer">')
  Blaze.render(Template.filter, $('#filterContainer')[0])

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
