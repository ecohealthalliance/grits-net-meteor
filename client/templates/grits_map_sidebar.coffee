_isDrawing = false;
window._rectangle = null;

# draw a rectangle on the map
#
# @note inspiration from https://github.com/Leaflet/Leaflet.draw
class GritsRectangle
  constructor: (sidebarElement, map, allNodes) ->
    self = this
    self._container = sidebarElement
    self._map = map
    self._allNodes = allNodes

    self._actionMenuTmpl = _.template('<ul id="<%= obj.id %>" class="action-menu"></ul>')
    self._actionTmpl = _.template('<li><div class="btn btn-sm btn-primary action-menu-<%= obj.name %>"><span><%= obj.name %></span></div></li>')
    self._actions = {}

    self._shape = null
    self._start = null
    self._stop = null
    self._drawing = false
    self._options =
      stroke: true
      color: 'blue',
      weight: 2
      opacity: 0.5
      fill: true
      fillColor: null
      fillOpacity: 0.2
      clickable: true

    self._bindMapEvents()
    self._buildActionMenu()

    # default action
    self.addAction('Apply', (e) ->
      self.apply()
      return
    )
    return
  _bindMapEvents: () ->
    self = this
    self._map.dragging.disable()
    self._map._container.style.cursor = 'crosshair'
    self._map.on('mousedown', self.onMouseDown, self)
    self._map.on('mouseup', self.onMouseUp, self)
    self._map.on('mousemove', self.onMouseMove, self)
  addAction: (name, handler) ->
    self = this
    $action = self._actionMenu.append(self._actionTmpl({name: name}))
    $action.on('click', handler)
    self._actions[name] = $action
  _buildActionMenu: () ->
    self = this
    self._actionMenuId = uuid.v4()
    self._actionMenu = $(self._actionMenuTmpl({id: self._actionMenuId})).appendTo('body')
    width = self._container.innerWidth()
    height = self._container.innerWidth()
    top = self._container.offset().top
    left = self._container.offset().left
    self._actionMenu.css({top: top, left: (left + width)}).show()
    return
  onMouseUp: (e) ->
    self = this
    self._stop = e.latlng
    self._drawing = false
    #self.remove()
    return
  onMouseDown: (e) ->
    self = this
    self._start = e.latlng
    self._drawing = true
    return
  onMouseMove: (e) ->
    self = this
    if (self._drawing && self.isStartNotEqualEnd())
      self.draw(e.latlng)
    return
  isStartNotEqualEnd: () ->
    self = this
    return JSON.stringify(self._start) != JSON.stringify(self._stop)
  draw: (latLng) ->
    self = this
    if self._shape != null
      self._shape.setBounds(new L.LatLngBounds(self._start, latLng))
    else
      self._shape = new L.Rectangle(new L.LatLngBounds(self._start, latLng), self.options)
      self._map.addLayer(self._shape)
    return
  _filterNodes: () ->
    self = this
    nodes = []
    if self._shape != null
      bounds = self._shape.getBounds()
      nodes = _.filter(self._allNodes, (node) -> bounds.contains(new L.LatLng(node.latLng[0], node.latLng[1])))
    return nodes
  apply: () ->
    self = this
    if self._shape != null
      Template.gritsOverlay.show()
      nodes = self._filterNodes()
      # erase any previous departures
      GritsFilterCriteria.setDepartures(null)
      # set the filtered nodes as the new origin
      departureSearch = Template.gritsFilter.getDepartureSearch()
      departureSearch.tokenfield('setTokens', _.pluck(nodes, '_id'))
      async.nextTick(() ->
        # apply the filter
        GritsFilterCriteria.apply((err, res) ->
          if res
            Template.gritsOverlay.hide()
            self.reset()
        )
      )
  reset: () ->
    self = this
    if self._shape != null
      self._map.removeLayer(self._shape)
      self._shape = null
    self._start = null
    self._stop = null
    return
  remove: () ->
    self = this
    self._map.off('mouseup', self.onMouseUp, self)
    self._map.off('mousedown', self.onMouseDown, self)
    self._map.off('mousemove', self.onMouseMove, self)
    if self._shape != null
      self._map.removeLayer(self._shape)
    self._map._container.style.cursor = ''
    self._map.dragging.enable()
    self._actionMenu.remove()
    return

Template.gritsMapSidebar.events
  'click #sidebar-plus-button': (event) ->
    Template.gritsMap.getInstance().zoomIn()
    return
  'click #sidebar-minus-button': (event) ->
    Template.gritsMap.getInstance().zoomOut()
    return
  'mouseover #sidebar-draw-rectangle-tool': (event) ->
    $('#sidebar-draw-rectangle-tool').addClass('sidebar-highlight')
    return
  'mouseout #sidebar-draw-rectangle-tool': (event) ->
    if !_isDrawing
      $('#sidebar-draw-rectangle-tool').removeClass('sidebar-highlight')
    return
  'click #sidebar-draw-rectangle-tool': (event) ->
    if Template.gritsOverlay.isLoading()
      return
    map = Template.gritsMap.getInstance()
    _isDrawing = !_isDrawing # toggle
    if _isDrawing
      allNodesLayer = map.getGritsLayer('AllNodes')
      allNodesLayer.add()
      window._rectangle = new GritsRectangle($(event.target), map, allNodesLayer.getNodes())
    else
      allNodesLayer = map.getGritsLayer('AllNodes')
      allNodesLayer.remove()
      if window._rectangle != null
        window._rectangle.remove()
