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

# adds the default controls to the map specified
#
# @param [GritsMap] map - map to apply the default controls
addDefaultControls = (map) ->
  legendControl = new GritsControl('<div id="legendContainer"></div>', 8, 'bottomright', 'info')
  map.addControl(legendControl)
  Blaze.render(Template.gritsLegend, $('#legendContainer')[0])

  elementDetails = new GritsControl('<div id="elementDetailsContainer"></div>', 7, 'bottomright', 'info element-details')
  map.addControl(elementDetails)
  Blaze.render(Template.gritsElementDetails, $('#elementDetailsContainer')[0])

  zoomControl = L.control.zoom({position: 'topleft'})
  map.addControl(zoomControl)

  searchControl = new GritsControl('<div id="searchContainer">', 10, 'topleft', 'info filter-control')
  map.addControl(searchControl)
  Blaze.render(Template.gritsSearch, $('#searchContainer')[0])
  Blaze.render(Template.gritsFilter, $('#sidebar-advanced-filter')[0])

  #dataTableControl = new GritsControl('<div id="dataTableContainer"></div>', 7, 'bottomleft', 'info')
  #map.addControl(dataTableControl)
  Blaze.render(Template.gritsDataTable, $('#sidebar-flightData')[0])

Template.gritsMap.onCreated ->
  # Public API
  # Currently we declare methods above for documentation purposes then assign
  # to the Template.gritsFilter as a global export
  Template.gritsMap.getInstance = getInstance
  Template.gritsMap.setInstance = setInstance
  Template.gritsMap.addDefaultControls = addDefaultControls
