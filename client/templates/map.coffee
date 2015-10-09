#Global event handlers for node and path click events.
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
