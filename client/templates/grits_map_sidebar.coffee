_isDrawing = false
window._boundingBox = null # TODO: temporarily assign to window for development purposes

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
      window._boundingBox = new GritsBoundingBox($(event.target), map)
    else
      if window._boundingBox != null
        window._boundingBox.remove()
