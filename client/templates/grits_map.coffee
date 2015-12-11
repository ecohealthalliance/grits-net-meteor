# Template.gritsFilter
#
# When another meteor app adds grits:grits-net-meteor as a package
# Template.gritsFilter will be available globally.

_instance = null
_currentPath = null
_currentRow = null

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

# returns the current path
#
# @return [GritsPath] path, a GritsPath object
getCurrentPath = () ->
  return _currentPath

# returns the current row
getCurrentRow = () ->
  return _currentRow

# sets the current path
#
# @param [GritsPath] path, a GritsPath object
setCurrentPath = (path) ->
  _currentPath = path

# sets the current row
setCurrentRow = (row) ->
  _currentRow = row

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

  filterControl = new GritsControl('<div id="filterContainer">', 10, 'topleft', 'info')
  map.addControl(filterControl)
  Blaze.render(Template.gritsFilter, $('#filterContainer')[0])

  flightTableControl = new GritsControl('<div id="flightTableContainer"></div>', 7, 'bottomleft', 'info')
  map.addControl(flightTableControl)
  Blaze.render(Template.flightTable, $('#flightTableContainer')[0])

  #$('#flightTableElement').bootstrapTable({data: []})

  $('.exportData').click ->
    fileType = $(this).attr("data-type")
    switch fileType
      when 'json'
        $("#flightTableElement").tableExport
          type: 'json'
      when 'xml'
        $("#flightTableElement").tableExport
          type: 'xml'
      when 'csv'
        $("#flightTableElement").tableExport
          type: 'csv'
      when 'excel'
        $("#flightTableElement").tableExport
          type: 'excel'
      else
        return



clickRow = (row, id) ->
  $(_currentRow).removeClass('activeRow')
  oldPath = Template.gritsMap.getCurrentPath()
  path = $("path#" + id)[0]
  if row is _currentRow
    _currentRow = null
    Template.gritsMap.hidePathDetails()
    Template.gritsMap.setCurrentPath(null)
    oldPath.__data__.clicked = false
    path.__data__.clicked = false
    d3.select(oldPath).style('stroke', oldPath.__data__.color)
    return
  else
    $(row).removeClass('activeRow')
  _currentRow = row
  $(row).addClass('activeRow')
  if path is oldPath
    path.clicked = true
  if path.__data__.clicked
    _currentRow = null
    path.__data__.clicked = false
    d3.select(path).style('stroke', path.__data__.color)
    $(_currentRow).removeClass('activeRow')
    Template.gritsMap.setCurrentPath(path)
    return
  if oldPath isnt null
    d3p = d3.select(oldPath)
    oldPath.__data__.clicked = false
    d3p.style('stroke', oldPath.__data__.color)
  path.__data__.clicked = true
  path.__data__.element = path
  d3.select(path).style('stroke', 'blue')
  Template.gritsMap.setCurrentPath(path)
  Template.gritsMap.showPathDetails(path.__data__)
  return

updateFlightTable = ->
  flightTableBody = $("#flightTableBody")
  flightTableBody.empty()
  paths = Template.gritsMap.getInstance()._layers.Paths._data
  pathsByThroughput = []
  for key of paths
    if paths.hasOwnProperty(key)
      pathsByThroughput.push paths[key]
  if pathsByThroughput.length > 0
    pathsByThroughput.sort (a, b) ->
      a.throughput - (b.throughput)
    pathsByThroughput.reverse()
    for path of pathsByThroughput
      Blaze.renderWithData Template.flightTableRow, pathsByThroughput[path], flightTableBody[0]
  else
    $('#flightTableContainer').empty()
    Blaze.render(Template.flightTable, $('#flightTableContainer')[0])

Template.gritsMap.onCreated ->
  # Public API
  # Currently we declare methods above for documentation purposes then assign
  # to the Template.gritsFilter as a global export
  Template.gritsMap.getInstance = getInstance
  Template.gritsMap.setInstance = setInstance
  Template.gritsMap.getCurrentPath = getCurrentPath
  Template.gritsMap.setCurrentPath = setCurrentPath
  Template.gritsMap.getCurrentRow = getCurrentRow
  Template.gritsMap.setCurrentRow = setCurrentRow
  Template.gritsMap.hidePathDetails = hidePathDetails
  Template.gritsMap.showPathDetails = showPathDetails
  Template.gritsMap.showNodeDetails = showNodeDetails
  Template.gritsMap.addDefaultControls = addDefaultControls
  Template.gritsMap.clickRow = clickRow
  Template.gritsMap.updateFlightTable = updateFlightTable
