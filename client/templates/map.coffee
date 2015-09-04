do ->
  'use strict'

Meteor.gritsUtil =
  map: null
  baseLayers: null
  imagePath: 'packages/fuatsengul_leaflet/images'
  initWindow: (element, css) ->
    element = element or 'map'
    css = css or {'height': window.innerHeight} 
    $(window).resize ->
      $('#'+element).css css        
    $(window).resize()      
  initLeaflet: (element, view, baseLayers) ->
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
      layers: [ baseLayers[0] ]).setView(view.latlong, view.zoom)
    tempBaseLayers = {}
    for baseLayer in baseLayers        
      tempBaseLayers[baseLayer.options.layerName] = baseLayer
    @baseLayers = tempBaseLayers
    if baseLayers.length>1        
      L.control.layers(@baseLayers).addTo @map
    @addControls()
  populateMap: (flights) ->
    new L.mapPath(flight, Meteor.gritsUtil.map) for flight in flights      
  addControls: ->
    moduleSelector = L.control(position: 'topleft')
    moduleSelector.onAdd = @onAddHandler('info', '<b> Select a Module </b><div id="moduleSelectorDiv"></div>')
    moduleSelector.addTo @map
    $('#moduleSelector').appendTo('#moduleSelectorDiv').show()
  onAddHandler: (selector, html) ->
    ->
      @_div = L.DomUtil.create('div', selector)
      @_div.innerHTML = html
      L.DomEvent.disableClickPropagation @_div
      L.DomEvent.disableScrollPropagation @_div
      @_div

Template.body.helpers template_name: ->
  Session.get 'module'

Template.map.onCreated () ->

Template.map.onRendered () ->

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
  
  Meteor.gritsUtil.initLeaflet('grits-map', {'zoom':5,'latlng':[37.8, -92]}, baseLayers)
  
  #Meteor.gritsUtil.map.addLayer(L.MapNodes.getLayerGroup())
  
  #Meteor.gritsUtil.map.addLayer(L.MapPaths.getLayerGroup())
  
  L.layerGroup(L.MapPaths.mapPaths).addTo(Meteor.gritsUtil.map)
  
  L.layerGroup(L.MapNodes.mapNodes).addTo(Meteor.gritsUtil.map)
  
  this.autorun () ->
    if Session.get('flightsReady')
      #Meteor.gritsUtil.populateMap Flights.find().fetch()
      # we may listen for changes now the the collection has been fetched from
      # the server and is ready
      Flights.find().observeChanges(
        added: (id, fields) ->
          console.log 'added id: ', id
          console.log 'added fields: ', fields
          new (L.MapPath)(fields)
        changed: (id, fields) ->
          console.log 'changed fields: ', fields
          L.MapPaths.updatePath fields
        removed: (id) ->
          console.log 'remove id: ', id
          L.MapPaths.removePath id
      )