_isDrawing = false
_boundingBox = null
_lastMode = null

Template.gritsMapSidebar.helpers
  'MODE_EXPLORE': () ->
    return GritsConstants.MODE_EXPLORE
  'MODE_ANALYZE': () ->
    return GritsConstants.MODE_ANALYZE

Template.gritsMapSidebar.events
  'change #mode-toggle': (event) ->
    mode = $(event.target).data('mode')
    if _lastMode == mode
      return
    Session.set(GritsConstants.SESSION_KEY_MODE, mode)
    return
  'click #sidebar-plus-button': (event) ->
    Template.gritsMap.getInstance().zoomIn()
    return
  'click #sidebar-minus-button': (event) ->
    Template.gritsMap.getInstance().zoomOut()
    return
  'click #sidebar-draw-rectangle-tool': (event) ->
    if Template.gritsOverlay.isLoading()
      return
    map = Template.gritsMap.getInstance()
    _isDrawing = !_isDrawing # toggle
    if _isDrawing
      $('#sidebar-draw-rectangle-tool').addClass('sidebar-highlight')
      _boundingBox = new GritsBoundingBox($('.sidebar-tabs'), map)
    else
      $('#sidebar-draw-rectangle-tool').removeClass('sidebar-highlight')
      if _boundingBox != null
        _boundingBox.remove()

Template.gritsMapSidebar.onRendered ->
  self = this

  # keep the UI reactive with the current mode
  Tracker.autorun ->
    _lastMode = Session.get(GritsConstants.SESSION_KEY_MODE)
    $('#mode-toggle :input[data-mode="' + _lastMode + '"]').click()
