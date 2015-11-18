# Template.gritsFilter
#
# When another meteor app adds grits:grits-net-meteor as a package
# Template.gritsFilter will be available globally.
Template.gritsMap.map = null # leaflet map
Template.gritsMap.overlays = {}
Template.gritsMap.overlayControl = null

Template.gritsMap.nodeDetail = null # container for displaying nodeDetail.html
Template.gritsMap.pathDetail = null # container for displaying pathDetail.html
Template.gritsMap.currentPath = null # currently selected path on the map

Template.gritsMap.nodeLayer = null # the GritsNodeLayer instance
Template.gritsMap.pathLayer = null # the GritsPathLayer instance
Template.gritsMap.heatmapLayer = null # the GritsHeatmapLayer instance

Template.gritsMap.imagePath = 'packages/bevanhunt_leaflet/images'

# Initialize the window the map will be rendered
#
# @param [String] element - id of the containing div
# @param [JSON] css - CSS to be applied to the containing div
Template.gritsMap.initWindow = (element, css) ->
  element = element or 'map'
  css = css or {'height': window.innerHeight}
  $(window).resize ->
    $('#' + element).css css
  $(window).resize()

# Initialize leaflet map
#
# @param [String] element - id of the containing div
# @param [JSON] view - map view options
# @param [Array<L.tileLayer>] baseLayers - map layers
Template.gritsMap.initLeaflet = (element, view, baseLayers) ->
  L.Icon.Default.imagePath = @imagePath
  # sensible defaults if nothing specified
  element = element or 'grits-map'
  view = view or {}
  view.zoom = view.zoom or 5
  view.latlong = view.latlng or [
    37.8
    -92
  ]
  OpenStreetMap = L.tileLayer('http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    key: '1234'
    layerName: 'OpenStreetMap'
    styleId: 22677)
  baseLayers = baseLayers or [OpenStreetMap]
  @map = L.map(element,
    zoomControl: false
    noWrap: true
    maxZoom: 18
    minZoom: 0
    layers: [ baseLayers[0] ]).setView(view.latlong, view.zoom)
  tempBaseLayers = {}
  for baseLayer in baseLayers
    tempBaseLayers[baseLayer.options.layerName] = baseLayer
  @baseLayers = tempBaseLayers

  @pathLayer = new GritsPathLayer()
  @heatmapLayer = new GritsHeatmap()
  @nodeLayer = new GritsNodeLayer()

  @drawOverlayControls()
  @addControls()


# Draws the overlay controls within the control box in the upper-right
# corner of the map.  It uses @overlayControl to place the reference of
# the overlay controls.
Template.gritsMap.drawOverlayControls = () ->
  if @overlayControl == null
    @overlayControl = L.control.layers(@baseLayers, @overlays).addTo @map
  else
    @overlayControl.removeFrom(@map)
    @overlayControl = L.control.layers(@baseLayers, @overlays).addTo @map

# addOverlayControl, adds a new overlay control to the map
Template.gritsMap.addOverlayControl = (layerName, layerGroup) ->
  @overlays[layerName] = layerGroup
  @drawOverlayControls()

# removeOverlayControl, removes overlay control from the map
Template.gritsMap.removeOverlayControl = (layerName) ->
  if @overlays.hasOwnProperty layerName
    delete @overlays[layerName]
    @drawOverlayControls()

# addControl
#
# Add a single control to the map.
Template.gritsMap.addControl = (position, selector, content) ->
  control = L.control(position: position)
  control.onAdd = @onAddHandler(selector, content)
  control.addTo @map
  
# Adds control overlays to the map
# -Module Selector
# -Path details
# -Node details
Template.gritsMap.addControls = () ->
  pathDetails = L.control(position: 'bottomright')
  pathDetails.onAdd = @onAddHandler('info path-detail', '')
  pathDetails.addTo @map
  $('.path-detail').hide()
  
  nodeDetails = L.control(position: 'bottomright')
  nodeDetails.onAdd = @onAddHandler('info node-detail', '')
  nodeDetails.addTo @map
  $('.node-detail').hide()

  $(".path-detail-close").on 'click', ->
    $('.path-detail').hide()
    
# @note This method is used for initializing dialog boxes created via addControls
Template.gritsMap.onAddHandler = (selector, html) ->
  ->
    @_div = L.DomUtil.create('div', selector)
    @_div.innerHTML = html
    L.DomEvent.disableClickPropagation @_div
    L.DomEvent.disableScrollPropagation @_div
    @_div


# Clears the current node details and renders the current node's details
#
# @param [GritsNode] node - node for which details will be displayed
Template.gritsMap.showNodeDetails = (node) ->
  $('.node-detail').empty()
  $('.node-detail').hide()
  div = $('.node-detail')[0]
  @nodeDetail = Blaze.renderWithData Template.nodeDetails, node, div
  $('.node-detail').show()
  $('.node-detail-close').off().on('click', (e) ->
    $('.node-detail').hide()
  )

Template.gritsMap.updateNodeDetails = () ->
  if typeof @nodeDetail == 'undefined' or @nodeDetail == null
    return
  previousNode = @nodeDetail.dataVar.get()
  newNode = @nodeLayer.Nodes[previousNode._id]
  if typeof newNode == 'undefined' or newNode == null
    return
  @nodeDetail.dataVar.set(newNode)

# Clears the current path details and renders the current path's details
#
# @param [GritsPath] path - path for which details will be displayed
Template.gritsMap.showPathDetails = (path) ->
  $('.path-detail').empty()
  $('.path-detail').hide()
  div = $('.path-detail')[0]
  Blaze.renderWithData Template.pathDetails, path, div
  $('.path-detail').show()
  $('.path-detail-close').off().on('click', (e) ->
    $('.path-detail').hide()
  )

Template.gritsMap.updatePathDetails = () ->
  if typeof @pathDetail == 'undefined' or @pathDetail == null
    return
  previousPath = @pathDetail.dataVar.get()
  newPath = @pathLayer.Paths[previousPath._id]
  if typeof newPath == 'undefined' or newPath == null
    return
  @pathDetail.dataVar.set(newPath)

# @event builds the leaflet map when the map template is rendered
Template.gritsMap.onRendered ->
  Template.gritsMap.initWindow('grits-map', {'height': window.innerHeight})
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
  Template.gritsMap.initLeaflet('grits-map', {'zoom': 2,'latlng': [30,-20]}, baseLayers)

  # Add the filter to the map's controls.
  Template.gritsMap.addControl('topleft', 'info', '<div id="filterContainer">')
  Blaze.render(Template.gritsFilter, $('#filterContainer')[0])
