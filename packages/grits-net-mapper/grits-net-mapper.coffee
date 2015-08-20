Meteor.grits_net_mapper =
  map: null
  baseLayers: null
  imagePath: 'packages/fuatsengul_leaflet/images'
  initLeaflet: ->
    $(window).resize ->
      $('#map').css 'height', window.innerHeight
      return
    $(window).resize()
    # trigger resize event
    return
  initMap: (element, view) ->    
    L.Icon.Default.imagePath = @imagePath
    # sensible defaults if nothing specified
    element = element or 'map'
    view = view or {}
    view.zoom = view.zoom or 5
    view.latlong = view.latlong or [
      37.8
      -92
    ]
    mbUrl = 'https://{s}.tile.openstreetmap.org/{id}/{z}/{x}/{y}.png'
    Esri_WorldImagery = L.tileLayer('http://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {})
    cloudmade = L.tileLayer('http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      key: '1234'
      styleId: 22677)
    Stamen_Watercolor = L.tileLayer('http://stamen-tiles-{s}.a.ssl.fastly.net/watercolor/{z}/{x}/{y}.png',
      attribution: 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a> &mdash; Map data &copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
      minZoom: 1
      maxZoom: 16
      ext: 'png')
    @map = L.map(element,
      zoomControl: false
      layers: [ Esri_WorldImagery ]).setView(view.latlong, view.zoom)
    @baseLayers =
      'Stamen Watercolor': Stamen_Watercolor
      'Esri WorldImagery': Esri_WorldImagery
    L.control.layers(@baseLayers).addTo @map
    @addControls()
    return
  addControls: ->    
    moduleSelector = L.control(position: 'topleft')
    moduleSelector.onAdd = @onAddHandler('info', '<b> Select a Module </b><div id="moduleSelectorDiv"></div>')
    moduleSelector.addTo @map
    $('#moduleSelector').appendTo('#moduleSelectorDiv').show()
    return
  onAddHandler: (selector, html) ->
    ->
      @_div = L.DomUtil.create('div', selector)
      @_div.innerHTML = html
      L.DomEvent.disableClickPropagation @_div
      L.DomEvent.disableScrollPropagation @_div
      @_div
  drawPath: (pointList)->    
    firstpolyline = new (L.Polyline)(pointList,
      color: 'red'
      weight: 3
      opacity: 0.5
      smoothFactor: 1)
    firstpolyline.addTo @map