# Template.gritsFilter
#
# When another meteor app adds grits:grits-net-meteor as a package
# Template.gritsFilter will be available globally.

_instance = null

# returns the map instance
#
# @return [GritsMap] map, a GritsMap instance
getInstance = () ->
  return _instance

# sets the map instance
#
# @param [GritsMap] map, a GritsMap object
setInstance = (map) ->
  if typeof map == 'undefined'
    throw new Error('Requires a map to be defined')
    return
  if !map instanceof GritsMap
    throw new Error('Requires a valid map instance')
    return
  _instance = map

# clears the current node details and renders the current node's details
#
# @param [GritsNode] node - node for which details will be displayed
showNodeDetails = (node) ->
  $('.node-detail').empty()
  $('.node-detail').hide()
  div = $('.node-detail')[0]
  @nodeDetail = Blaze.renderWithData Template.nodeDetails, node, div
  $('.node-detail').show()
  $('.node-detail-close').off().on('click', (e) ->
    $('.node-detail').hide()
  )

# clears the current path details and renders the current path's details
#
# @param [GritsPath] path - path for which details will be displayed
showPathDetails = (path) ->
  $('.path-detail').empty()
  $('.path-detail').hide()
  div = $('.path-detail')[0]
  Blaze.renderWithData Template.pathDetails, path, div
  $('.path-detail').show()
  $('.path-detail-close').off().on('click', (e) ->
    $('.path-detail').hide()
  )

# clears the current path details
hidePathDetails = ->
  $('.path-detail').empty()
  $('.path-detail').hide()

# clears the current node details
hideNodeDetails = ->
  $('.node-detail').empty()
  $('.node-detail').hide()

# adds the default controls to the map specified
#
# @param [GritsMap] map - map to apply the default controls
addDefaultControls = (map) ->
  pathDetail = new GritsControl('', 7, 'bottomright', 'info path-detail')
  map.addControl(pathDetail)
  $('.path-detail').hide()

  nodeDetail = new GritsControl('', 7, 'bottomright', 'info node-detail')
  map.addControl(nodeDetail)
  $('.node-detail').hide()

  legendControl = new GritsControl('<div id="legendContainer"></div>', 8, 'bottomright', 'info')
  map.addControl(legendControl)
  Blaze.render(Template.gritsLegend, $('#legendContainer')[0])

  zoomControl = L.control.zoom({position:'topleft'})
  map.addControl(zoomControl)

  filterControl = new GritsControl('<div id="filterContainer">', 10, 'topleft', 'info filter-control')
  map.addControl(filterControl)
  Blaze.render(Template.gritsFilter, $('#filterContainer')[0])

  dataTableControl = new GritsControl('<div id="dataTableContainer"></div>', 7, 'bottomleft', 'info')
  map.addControl(dataTableControl)
  Blaze.render(Template.gritsDataTable, $('#dataTableContainer')[0])




Template.gritsMap.onCreated ->
  # Public API
  # Currently we declare methods above for documentation purposes then assign
  # to the Template.gritsFilter as a global export
  Template.gritsMap.getInstance = getInstance
  Template.gritsMap.setInstance = setInstance
  Template.gritsMap.hidePathDetails = hidePathDetails
  Template.gritsMap.showPathDetails = showPathDetails
  Template.gritsMap.showNodeDetails = showNodeDetails
  Template.gritsMap.addDefaultControls = addDefaultControls
