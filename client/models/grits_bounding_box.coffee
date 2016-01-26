# the maximum amount of nodes for a bounding box selection
_maxSelection = 1000
# draw a rectangle on the map
#
# @note inspiration from https://github.com/Leaflet/Leaflet.draw
class GritsBoundingBox
  constructor: (sidebarElement, map) ->
    self = this
    self._container = sidebarElement
    self._map = map
    #self._initialZoom = map.getZoom()
    #self._initialCenter = map.getCenter()
    self._initialZoom = self._map.options.zoom
    self._initialCenter = self._map.options.center

    self._nodesLayer = self._map.getGritsLayer('Nodes')
    self._nodesLayer.remove()

    self._pathsLayer = self._map.getGritsLayer('Paths')
    self._pathsLayer.remove()

    self._allNodesLayer = self._map.getGritsLayer('AllNodes')
    self._allNodesLayer.add()

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

    self._buildActionMenu()

    # enable selecting
    self._selecting = false

    # default action
    self.addAction('Apply', (e) -> self.apply())
    self.addAction('Select', _.bind(self._selectToggle, self))
    return
  _bindMapEvents: () ->
    self = this
    self._map.dragging.disable()
    self._map._container.style.cursor = 'crosshair'
    self._map.on('mousedown', self.onMouseDown, self)
    self._map.on('mouseup', self.onMouseUp, self)
    self._map.on('mousemove', self.onMouseMove, self)
    return self
  _unbindMapEvents: () ->
    self = this
    self._map.off('mouseup', self.onMouseUp, self)
    self._map.off('mousedown', self.onMouseDown, self)
    self._map.off('mousemove', self.onMouseMove, self)
    self._map._container.style.cursor = ''
    self._map.dragging.enable()
    return self
  _selectToggle: () ->
    self = this
    self._selecting = !self._selecting
    if self._selecting
      self._selectOn()
    else
      self._selectOff()
    return
  _selectOn: () ->
    self = this
    self._selecting = true
    self._bindMapEvents()
    $('.action-menu-Select').css({opacity: 0.35})
  _selectOff: () ->
    self = this
    self._selecting = false
    self._unbindMapEvents()
    $('.action-menu-Select').css({opacity: 0.75})
    return
  addAction: (name, handler) ->
    self = this
    self._actionMenu.append(self._actionTmpl({name: name}))
    $action = $('.action-menu-'+name)
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
      nodes = _.filter(self._allNodesLayer.getNodes(), (node) -> bounds.contains(new L.LatLng(node.latLng[0], node.latLng[1])))
    if nodes.length > _maxSelection
      return {error: true, message: 'Please narrow your selection. ' + nodes.length + ' is greater than ' + _maxSelection}
    return new GritsMetaNode(nodes, self._map)
  apply: () ->
    self = this
    if self._shape != null
      Template.gritsOverlay.show()
      # reset any previous metaNodes
      GritsMetaNode.reset(self._map)
      # apply the boundingbox filter
      metaNode = self._filterNodes()
      if metaNode.hasOwnProperty('error')
        toastr.warning(metaNode.message)
        Template.gritsOverlay.hide()
        self.reset()
        return
      # erase any previous departures
      GritsFilterCriteria.setDepartures(null)
      # set the meta node as the new origin
      departureSearch = Template.gritsFilter.getDepartureSearch()
      departureSearch.tokenfield('setTokens', metaNode._id)
      async.nextTick(() ->
        # apply the filter
        GritsFilterCriteria.apply((err, res) ->
          Template.gritsOverlay.hide()
          self.reset()
          if res
            GritsMetaNode.addLayerGroupToMap(self._map)
            self._map.fitBounds(metaNode.bounds)
        )
      )
  reset: () ->
    self = this
    if self._shape != null
      self._map.removeLayer(self._shape)
      self._shape = null
    self._start = null
    self._stop = null
    self._selectOff()
    return
  remove: () ->
    self = this
    if self._shape != null
      self._map.removeLayer(self._shape)
    self._selectOff()
    self._actionMenu.remove()
    self._allNodesLayer.remove()
    #GritsFilterCriteria.setDepartures(null)
    self._map.setView(self._initialCenter, self._initialZoom)
    GritsMetaNode.reset(self._map)
    return
