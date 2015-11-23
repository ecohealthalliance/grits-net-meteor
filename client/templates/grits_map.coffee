# Template.gritsFilter
#
# When another meteor app adds grits:grits-net-meteor as a package
# Template.gritsFilter will be available globally.

_instance = null


Template.gritsMap.currentPath = null # currently selected path on the map

Template.gritsMap.getInstance = () ->
  return _instance

Template.gritsMap.setInstance = (map) ->
  if typeof map == 'undefined'
    throw new Error('Requires a map to be defined')
    return
  if !map instanceof GritsMap
    throw new Error('Requires a valid map instance')
    return
  _instance = map

# Clears the current node details and renders the current node's details
#
# @param [GritsNode] node - node for which details will be displayed
Template.gritsMap.showNodeDetails = (node) ->
  $('.node-detail').empty()
  $('.node-detail').hide()
  div = $('.node-detail')[0]
  @nodeDetail = Blaze.renderWithData Template.nodeDetails, node, div
  $('.node-detail').show()
  $('.node-detail-close').off().on('click', (e) ->
    $('.node-detail').hide()
  )

# Clears the current path details and renders the current path's details
#
# @param [GritsPath] path - path for which details will be displayed
Template.gritsMap.showPathDetails = (path) ->
  $('.path-detail').empty()
  $('.path-detail').hide()
  div = $('.path-detail')[0]
  Blaze.renderWithData Template.pathDetails, path, div
  $('.path-detail').show()
  $('.path-detail-close').off().on('click', (e) ->
    $('.path-detail').hide()
  )
