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
    $('.dtHidden').show()
    fileType = $(event.currentTarget).attr("data-type")
    activeTable = $('.dataTableContent').find('.active').find('.table.dataTable')
    if activeTable.length
      activeTable.tableExport({type: fileType})
    $('.dtHidden').hide()
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
  # get the map instance
  self.map = Template.gritsMap.getInstance()
  # get the heatmap layer
  heatmapLayerGroup = self.map.getGritsLayerGroup(GritsConstants.HEATMAP_GROUP_LAYER_ID)
  self.heatmapLayer = heatmapLayerGroup.find(GritsConstants.HEATMAP_LAYER_ID)

  Tracker.autorun ->
    # determine the current layer group
    mode = Session.get(GritsConstants.SESSION_KEY_MODE)
    layerGroup = GritsLayerGroup.getCurrentLayerGroup()

    # update the table reactively to the current visible paths
    data = layerGroup.getPathLayer().visiblePaths.get()
    if _.isEmpty(data)
      self.paths.set([])
    else
      sorted = _.sortBy(data, (path) ->
        return path.throughput * -1
      )
      self.paths.set(sorted)

    # update the table reactively to the current visible nodes
    data = layerGroup.getNodeLayer().visibleNodes.get()
    if _.isEmpty(data)
      self.nodes.set([])
    else
      sorted = _.sortBy(data, (node) ->
        return (node.incomingThroughput + node.outgoingThroughput) * -1
      )
      nodes = _formatNodeData(sorted)
      self.nodes.set(nodes)

  Tracker.autorun ->
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
        hmms = []
        for heatmap in heatmaps
          for airport in Meteor.gritsUtil.airports
            if heatmap.code is airport._id
              hmm = heatmap
              hmm.node = airport
              hmms.push(hmm)
        self.heatmaps.set(hmms)
    _tablesChanged = true
