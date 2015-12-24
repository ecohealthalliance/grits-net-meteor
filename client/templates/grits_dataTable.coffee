# Template.gritsDataTable
#
# When another meteor app adds grits:grits-net-meteor as a package
# Template.gritsDataTable will be available globally.
_previousPath = null # placeholde for the last clicked path

# highlights the path table row
#
# @param [Object] a GritsPath object
highlightPathTableRow = (path) ->
  if !(path instanceof GritsPath)
    return
  $row = $("[data-id=#{path._id}]")
  # remove any previously clicked rows
  $table = $row.closest('table')
  $table.find('.activeRow').removeClass('activeRow')
  # add the active class to this row
  $row.addClass('activeRow')

# formats the heatmap data for display in the template
#
# @param [Array] an Array of heatmap data
# @return [Array] an Array of objects
_formatHeatmapData = (data) ->
  heatmaps = []
  if _.isEmpty(data)
    return heatmaps
  count = 0
  _.each(data, (a) ->
    heat = {
      _id: 'heatmapRow' + ++count
      code: a[4]
      latitude: +(a[0]).toFixed(5)
      longitude: +(a[1]).toFixed(5)
      intensity: +(a[3]).toFixed(3)
    }
    heatmaps.push(heat)
  )
  return heatmaps

# formats the node data for display in the template
#
# @param [Array] an Array of GritsNode
# @return [Array] an Array of objects
_formatNodeData = (data) ->
  nodes = []
  if _.isEmpty(data)
    return nodes
  count = 0
  _.each(data, (n) ->
    node = _.extend(n, {total: n.incomingThroughput + n.outgoingThroughput})
    nodes.push(node)
  )
  return nodes

Template.gritsDataTable.events({
  'click .pathTableRow': (event, template) ->
    # get the clicked row
    $row = $(event.currentTarget)
    # remove any previously clicked rows
    $table = $row.closest('table')
    $table.find('.activeRow').removeClass('activeRow')
    # find the path from template.paths using the DOM's id
    _id = $row.data('id')
    paths = template.paths.get()
    path = _.find(paths, (path) -> path._id == _id)
    if _.isUndefined(path)
      return
    element = $('path#'+_id)[0]
    if _.isUndefined(element)
      return
    # simulate a click on the path
    path.eventHandlers.click(element)
    # if we're not clicking on ourself
    if _previousPath != path
      # add the active class to this row
      $row.addClass('activeRow')
    _previousPath = path
    return
  'click .exportData': (event) ->
    fileType = $(event.currentTarget).attr("data-type")
    activeTable = $('.dataTableContent').find('.active').find('.table.dataTable')
    if activeTable.length
      activeTable.tableExport({type: fileType})
    return
})

Template.gritsDataTable.helpers({
  paths: () ->
    if _.isUndefined(Template.instance().paths)
      return []
    else
      return Template.instance().paths.get()
  nodes: () ->
    if _.isUndefined(Template.instance().nodes)
      return []
    else
      return Template.instance().nodes.get()
  heatmaps: () ->
    if _.isUndefined(Template.instance().heatmaps)
      return []
    else
      return Template.instance().heatmaps.get()
})

Template.gritsDataTable.onCreated ->
  # initialize reactive-var to hold reference to the paths, nodes, and heatmap data
  this.paths = new ReactiveVar([])
  this.nodes = new ReactiveVar([])
  this.heatmaps = new ReactiveVar([])
  # Public API
  Template.gritsDataTable.highlightPathTableRow = highlightPathTableRow

Template.gritsDataTable.onRendered ->
  self = this

  # get the map instance and layers
  map = Template.gritsMap.getInstance()
  pathsLayer = map.getGritsLayer('Paths')
  nodesLayer = map.getGritsLayer('Nodes')
  heatmapLayer = map.getGritsLayer('Heatmap')

  self.autorun ->
    # when the paths are finished loading, set the template data to the result
    pathsLoaded = pathsLayer.hasLoaded.get()
    if pathsLoaded
      data = pathsLayer.getPaths()
      if _.isEmpty(data)
        self.paths.set([])
      else
        sorted = _.sortBy(data, (path) ->
          return path.throughput * -1
        )
        self.paths.set(sorted)
    # when the nodes are finished loading, set the template data to the result
    nodesLoaded = nodesLayer.hasLoaded.get()
    if nodesLoaded
      data = nodesLayer.getNodes()
      if _.isEmpty(data)
        self.nodes.set([])
      else
        sorted = _.sortBy(data, (node) ->
          return (node.incomingThroughput + node.outgoingThroughput) * -1
        )
        nodes = _formatNodeData(sorted)
        self.nodes.set(nodes)
    # when the heatmap is finished loading, set the template data to the result
    heatmapLoaded = heatmapLayer.hasLoaded.get()
    if heatmapLoaded
      data = heatmapLayer.getData()
      if _.isEmpty(data)
        self.heatmaps.set([])
      else
        sorted = _.sortBy(data, (data) ->
          return data[2] * -1
        )
        heatmaps = _formatHeatmapData(sorted)
        self.heatmaps.set(heatmaps)