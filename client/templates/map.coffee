Meteor.startup ->
  window.LUtil.initLeaflet()
window.LUtil =
  map: null
  baseLayers: null
  imagePath: 'packages/fuatsengul_leaflet/images'
  initLeaflet: ->
    $(window).resize ->
      $('#map').css 'height', window.innerHeight
      return
    $(window).resize()
  initMap: (element, view) ->
    Esri_WorldImagery = undefined
    MapQuestOpen_OSM = undefined
    cloudmade = undefined
    L.Icon.Default.imagePath = @imagePath
    element = element or 'map'
    view = view or {}
    view.zoom = view.zoom or 5
    view.latlong = view.latlong or [
      37.8
      -92
    ]
    Esri_WorldImagery = L.tileLayer('http://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {})
    cloudmade = L.tileLayer('http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      key: '1234'
      styleId: 22677)
    MapQuestOpen_OSM = L.tileLayer('http://otile{s}.mqcdn.com/tiles/1.0.0/{type}/{z}/{x}/{y}.{ext}',
      type: 'map'
      ext: 'jpg'
      subdomains: '1234')
    @map = L.map(element,
      zoomControl: false
      worldCopyJump: true
      layers: [ MapQuestOpen_OSM ]).setView(view.latlong, view.zoom)
    @baseLayers =
      'Esri WorldImagery': Esri_WorldImagery
      'MapQuestOpen_OSM': MapQuestOpen_OSM
    L.control.layers(@baseLayers).addTo @map
    @addControls()
  populateMap: (flights) ->
    flight = undefined
    i = undefined
    len = undefined
    results = undefined
    results = []
    i = 0
    len = flights.length
    while i < len
      flight = flights[i]
      results.push new (L.mapPath)(flight, window.LUtil.map)
      i++
    results
  addControls: ->
    moduleSelector = undefined
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
  
Template.map.onRendered ->
  window.LUtil.initMap()
  @autorun ->
    initializing = true
    if Session.get('flightsReady')
      window.LUtil.populateMap Flights.find().fetch()
      # we may listen for changes now the the collection has been fetched from
      # the server and populated, conversely we could not call the initial
      # window.Lutil.populateMap, remove the check on initializing, and let
      # the added method populate the map as the collection is being loaded.
      Flights.find().observeChanges(
        added: (id, fields) ->
          if not initializing
            console.log 'id: ', id
            console.log 'fields: ', fields
            new (L.MapPath)(fields)
        changed: (id, fields) ->
          L.MapPaths.updatePath fields
        removed: (id) ->
          L.MapPaths.removePath id
      )
      initilizing = false