# Template.gritsDataTable
#
# When another meteor app adds grits:grits-net-meteor as a package
# Template.gritsDataTable will be available globally.
_previousPath = null # placeholder for the last clicked path

_tablesChanged = false

# highlights the path table row
#
# @param [Object] a GritsPath object
highlightPathTableRow = (path) ->
  if !(path instanceof GritsPath)
    return
  $row = $("tr[data-id=#{path._id}]")
  # remove any previously clicked rows
  $table = $row.closest('table')
  $table.find('.activeRow').removeClass('activeRow')
  if _previousPath != path
    # add the active class to this row and remove any background-color
    $row.addClass('activeRow').css({'background-color':''})
    # reset the previous path background-color
    if !_.isNull(_previousPath)
      $previousPath = $("tr[data-id=#{_previousPath._id}]")
      $previousPath.css({'background-color':_previousPath.color})
    # this path becomes the previousPath
    _previousPath = path
  else
    # clicked on same path, reset the color and set _previousPath to null
    $row.css({'background-color':path.color})
    _previousPath = null
  return

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
      code: a[3]
      latitude: +(a[0]).toFixed(5)
      longitude: +(a[1]).toFixed(5)
      intensity: +(a[2]).toFixed(3)
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

_refreshTables = () ->
  if _tablesChanged
    _tablesChanged = false
    $("#pathsTable").trigger('update')
    $("#nodesTable").trigger('update')
    $("#heatmapTable").trigger('update')

Template.gritsDataTable.events({
  'click .pathTableRow': (event, template) ->
    # get the clicked row
    $row = $(event.currentTarget)
    # find the path from template.paths using the DOM's id
    _id = $row.data('id')
    paths = template.paths.get()
    path = _.find(paths, (path) -> path._id == _id)
    if _.isUndefined(path)
      return
    element = $('#'+path.elementID)[0]
    if _.isUndefined(element)
      return
    # simulate a click on the path
    path.eventHandlers.click(element)
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
  getPathThroughputColor: (path) ->
    if _.isUndefined(path)
      return ''
    if _.isUndefined(Template.instance().pathsLayer)
      return ''
    return Template.instance().pathsLayer._getNormalizedColor(path)
  getNodeThroughputColor: (node) ->
    if _.isUndefined(node)
      return ''
    if _.isUndefined(Template.instance().nodesLayer)
      return ''
    return Template.instance().nodesLayer._getNormalizedColor(node)
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

  _dataTableUpdateInterval = setInterval _refreshTables, 1000
  # get the map instance and layers
  self.map = Template.gritsMap.getInstance()
  self.pathsLayer = self.map.getGritsLayer('Paths')
  self.nodesLayer = self.map.getGritsLayer('Nodes')
  self.heatmapLayer = self.map.getGritsLayer('Heatmap')

  self.autorun ->
    # when the paths have changed, set the template data to the result

    # update the table reactively to the current visible paths
    data = self.pathsLayer.visiblePaths.get()
    if _.isEmpty(data)
      self.paths.set([])
    else
      sorted = _.sortBy(data, (path) ->
        return path.throughput * -1
      )
      self.paths.set(sorted)

    # update the table reactively to the current visible nodes
    data = self.nodesLayer.visibleNodes.get()
    if _.isEmpty(data)
      self.nodes.set([])
    else
      sorted = _.sortBy(data, (node) ->
        return (node.incomingThroughput + node.outgoingThroughput) * -1
      )
      nodes = _formatNodeData(sorted)
      self.nodes.set(nodes)

    # when the heatmap is finished loading, set the template data to the result
    heatmapLoaded = self.heatmapLayer.hasLoaded.get()
    if heatmapLoaded
      data = self.heatmapLayer.getData()
      if _.isEmpty(data)
        self.heatmaps.set([])
      else
        sorted = _.sortBy(data, (data) ->
          return data[2] * -1
        )
        heatmaps = _formatHeatmapData(sorted)
        self.heatmaps.set(heatmaps)
    _tablesChanged = true
