# @note L.MapPath click event handler
@pathHandler =
  click: (path) ->
    path.clicked = true
    Meteor.gritsUtil.showPathDetails(path)
    #Meteor.gritsUtil.currentPath = path
  getCurrentPath: ->
    return Meteor.gritsUtil.currentPath
  setCurrentPath: (path) ->
    Meteor.gritsUtil.currentPath = path
  unClick: (path) ->
    path.clicked = false
    Meteor.gritsUtil.hidePathDetails()
    @setCurrentPath(null)

# @event builds the leaflet map when the map template is rendered
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
  Meteor.gritsUtil.initLeaflet('grits-map', {'zoom': 2,'latlng': [30,-20]}, baseLayers)

  # Add the filter to the map's controls.
  Meteor.gritsUtil.addControl('topleft', 'info', '<div id="filterContainer">')
  Blaze.render(Template.filter, $('#filterContainer')[0])
