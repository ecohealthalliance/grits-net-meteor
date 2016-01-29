_isDrawing = false
_boundingBox = null

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
      _boundingBox = new GritsBoundingBox($('.sidebar-tabs'), map)
    else
      if _boundingBox != null
        _boundingBox.remove()
