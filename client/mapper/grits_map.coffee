_imagePath = 'packages/bevanhunt_leaflet/images'
# Creates an instance of a map
#
# @param [String]
# @param [Object] options, Leaflet map options + height
# @see http://leafletjs.com/reference.html#map-options
class GritsMap extends L.Map
  constructor: (element, options) ->
    @_name = 'GritsMap'
    @_element = element or 'grits-map'

    @_gritsOverlayControl = null
    @_gritsOverlays = {}
    @_gritsTileLayers = {}
    @_gritsLayers = {}

    L.Icon.Default.imagePath = _imagePath

    OpenStreetMap = L.tileLayer('http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      key: '1234'
      layerName: 'OpenStreetMap'
      styleId: 22677)

    if typeof options == 'undefined'
      @_options = {
        height: window.innerHeight
        center: [37.8, -92]
        zoomControl: false
        noWrap: true
        maxZoom: 18
        minZoom: 0
        layers: [OpenStreetMap]
      }
    else
      @_options = options

    if typeof @_options.layers == 'undefined'
      @_options.layers = [OpenStreetMap]

    if typeof @_options.height == 'undefined'
      @_options.height = window.innerHeight;

    height = @_options.height
    document.getElementById(@_element).style.height = height + 'px'
    
    for layer in @_options.layers
      @_gritsTileLayers[layer.options.layerName] = layer
    
    @_options.layers = [@_options.layers[0]]
    super(@_element, @_options)
    
    @_drawOverlayControls()  
    return

  # adds a layer reference to the map object
  #
  # @note This does not add the layer to the Leaflet map.  Its just a container
  # @param [Object] layer, a GritsLayer instance
  addGritsLayer: (layer) ->
    if typeof layer == 'undefined'
      throw new Error('A layer must be defined')
      return
    if !layer instanceof GritsLayer
      throw new Error('A map requires a valid GritsLayer instance')
      return
    @_layers[layer._name] = layer
    return layer

  # gets a layer refreence from the map object
  #
  # @param [String] name, a string containing the name of the layer as shown
  #  in the UI layer controls
  getGritsLayer: (name) ->
    if typeof name == 'undefined'
      throw new Error('A name must be defined')
      return
    if @_layers.hasOwnProperty(name) == true
      return @_layers[name]
    return null

  # draws the overlay controls within the control box in the upper-right
  # corner of the map.  It uses @_gritsOverlayControl to place the reference of
  # the overlay controls.
  _drawOverlayControls: () ->
    if @_gritsOverlayControl == null
      @_gritsOverlayControl = L.control.layers(@_gritsTileLayers, @_gritsOverlays).addTo this
    else
      @_gritsOverlayControl.removeFrom(this)
      @_gritsOverlayControl = L.control.layers(@_gritsTileLayers, @_gritsOverlays).addTo this
    return

  # adds a new overlay control to the map
  #
  # @param [String] layerName, string containing the name of the layer
  # @param [Object] layerGroup, the layerGroup object to add to the map controls
  addOverlayControl: (layerName, layerGroup) ->
    @_gritsOverlays[layerName] = layerGroup
    @_drawOverlayControls()
    return

  # removes overlay control from the map
  #
  # @param [String] layerName, string containing the name of the layer
  removeOverlayControl: (layerName) ->
    if @_gritsOverlays.hasOwnProperty layerName
      delete @_gritsOverlays[layerName]
      @_drawOverlayControls()
    return
