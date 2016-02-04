# GritsControl represents a control on the map
#
# @param [String] htmlContent, the content of the control
# @param [Integer] zindex, the z-index to be applied to the container
# @param [String] position, one of 'topleft', 'topright', 'bottomleft',
#  or 'bottomright'
# @param [String] css, the css class to be applied to the container
class GritsControl extends L.Control
  constructor: (htmlContent, zIndex, position, css) ->
    if typeof htmlContent == 'undefined'
      throw new Error('GritsConrol must have htmlContent defined')
    @position = position or 'bottomleft'
    @options =
      position: position
    @_htmlContent = htmlContent
    @_css = css or 'info'
    @_zIndex = zIndex or 7 # the leaflet default
    super(this)

  onAdd: (map) ->
    @_map = map
    container = L.DomUtil.create('div', @_css)
    container.innerHTML = @_htmlContent
    container.style.zIndex = @_zIndex
    L.DomEvent.disableClickPropagation(container)
    L.DomEvent.disableScrollPropagation(container)
    return container
