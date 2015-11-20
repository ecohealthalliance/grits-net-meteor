# Template.gritsFilter
#
# When another meteor app adds grits:grits-net-meteor as a package
# Template.gritsFilter will be available globally.

_imagePath = 'packages/bevanhunt_leaflet/images'
_overlays = {}
_overlayControl = null

Template.gritsMap.map = null # leaflet map
Template.gritsMap.nodeDetail = null # container for displaying nodeDetail.html
Template.gritsMap.pathDetail = null # container for displaying pathDetail.html
Template.gritsMap.currentPath = null # currently selected path on the map
Template.gritsMap.nodeLayer = null # the GritsNodeLayer instance
Template.gritsMap.pathLayer = null # the GritsPathLayer instance
Template.gritsMap.heatmapLayer = null # the GritsHeatmapLayer instance

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
  L.Icon.Default.imagePath = _imagePath
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

  @heatmapLayer = new GritsHeatmap()
  @pathLayer = new GritsPathLayer()  
  @nodeLayer = new GritsNodeLayer()

  @drawOverlayControls()
  @_addDefaultControls()
  return

# drawOverlayControls
#
# Draws the overlay controls within the control box in the upper-right
# corner of the map.  Overlay controls provide a checkbox to toggle
# a layer on/off
Template.gritsMap.drawOverlayControls = () ->
  if _overlayControl == null
    _overlayControl = L.control.layers(@baseLayers, _overlays).addTo @map
  else
    _overlayControl.removeFrom(@map)
    _overlayControl = L.control.layers(@baseLayers, _overlays).addTo @map
  return

# addOverlayControl
#
# adds a new overlay control to the map, this will also add the layerGroup
Template.gritsMap.addOverlayControl = (layerName, layerGroup) ->
  _overlays[layerName] = layerGroup
  @drawOverlayControls()
  return

# removeOverlayControl
#
# removes overlay control from the map, this will also remove the layerGroup
Template.gritsMap.removeOverlayControl = (layerName) ->
  if _overlays.hasOwnProperty layerName
    delete _overlays[layerName]
    @drawOverlayControls()
  return

# addControl
#
# Add a single control to the map.
Template.gritsMap.addControl = (position, selector, content) ->
  control = L.control(position: position)
  control.onAdd = @_onAddHandler(selector, content)
  control.addTo @map
  
# addControls
#
# Adds the default controls to the map
# -Path details
# -Node details
Template.gritsMap._addDefaultControls = () ->
  pathDetails = L.control(position: 'bottomright')
  pathDetails.onAdd = @_onAddHandler('info path-detail', '')
  pathDetails.addTo @map
  $('.path-detail').hide()
  
  nodeDetails = L.control(position: 'bottomright')
  nodeDetails.onAdd = @_onAddHandler('info node-detail', '')
  nodeDetails.addTo @map
  $('.node-detail').hide()

  $(".path-detail-close").on 'click', ->
    $('.path-detail').hide()

# onAddHandler
#
# @note This method is used for initializing dialog boxes created via addControls
Template.gritsMap._onAddHandler = (selector, html) ->
  ->
    _div = L.DomUtil.create('div', selector)
    _div.innerHTML = html
    L.DomEvent.disableClickPropagation _div
    L.DomEvent.disableScrollPropagation _div
    _div

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

# setView
#
# wrapper, Sets the view of the map (geographical center and zoom) with the given animation options.
# @param [Array] latLng - the poing
# @param [Integet] zoom - the zoom level
# @param [Object] options - the animation options
Template.gritsMap.setView = (latLng, zoom, options) ->
  if _.isNull(@map)
    throw new Error('The map has not be initialized.')
  @map.setView(latLng, zoom, options)
  return

# fitBounds
#
# wrapper, Sets a map view that contains the given geographical bounds with the maximum zoom level possible.
Template.gritsMap.fitBounds = (latLngBounds, options) ->
  if _.isNull(@map)
    throw new Error('The map has not be initialized.')
  @map.fitBounds(latLngBounds, options)
  return

# setMaxBounds
#
# wrapper, Restricts the map view to the given bounds
Template.gritsMap.setMaxBounds = (latLngBounds) ->
  if _.isNull(@map)
    throw new Error('The map has not be initialized.')
  @map.setMaxBounds(latLngBounds)
  return

# getBounds
#
# wrapper, Returns the LatLngBounds of the current map view.
Template.gritsMap.getBounds = (latLngBounds) ->
  if _.isNull(@map)
    throw new Error('The map has not be initialized.')
  @map.getBounds()
  return

# setZoom
#
# wrapper, Sets the zoom of the map.
# @param [Array] latLng - the poing
# @param [Integet] zoom - the zoom level
# @param [Object] options - the animation options
Template.gritsMap.setZoom = (zoom, options) ->
  if _.isNull(@map)
    throw new Error('The map has not be initialized.')
  @map.setZoom(zoom, options)
  return

# zoomIn
#
# wrapper, Increases the zoom of the map by delta (1 by default).
# @param [Integer] delta
Template.gritsMap.zoomIn = (delta) ->
  if _.isNull(@map)
    throw new Error('The map has not be initialized.')
  @map.zoomIn(delta)
  return

# zoomOut
#
# wrapper, Decreases the zoom of the map by delta (1 by default).
# @param [Integer] delta
Template.gritsMap.zoomOut = (delta) ->
  if _.isNull(@map)
    throw new Error('The map has not be initialized.')
  @map.zoomOut(delta)
  return

# getZoom
#
# wrapper, Returns the current zoom of the map view.
Template.gritsMap.getZoom = () ->
  if _.isNull(@map)
    throw new Error('The map has not be initialized.')
  @map.getZoom()
  return

# panTo
#
# wrapper, Pans the map to a given center. Makes an animated pan if new center is not more than one screen away from the current one.
Template.gritsMap.panTo = (latLng, options) ->
  if _.isNull(@map)
    throw new Error('The map has not be initialized.')
  @map.panTo(latLng, options)
  return
  
# remove
#
# wrapper, Destroys the map and clears all related event listeners.
Template.gritsMap.remove = () ->
  if _.isNull(@map)
    throw new Error('The map has not be initialized.')
  @map.remove()
  return

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
