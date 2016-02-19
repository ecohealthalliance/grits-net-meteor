# Template.gritsDataTable
#
# When another meteor app adds grits:grits-net-meteor as a package
# Template.gritsDataTable will be available globally.
_previousPath = null # placeholder for the last clicked path

_tablesChanged = new ReactiveVar(false)

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

# update the simulationProgress bar
_updateSimulationProgress = (progress) ->
  $('.simulation-progress').css({width: progress})
  return progress

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
  simulationProgress: () ->
    progress = Template.gritsSearch.simulationProgress.get() + '%'
    return _updateSimulationProgress(progress)
  getAdditionalInfo: (airport) ->
    additionalInfo = ''
    if airport.hasOwnProperty('city') && airport.city != ''
      additionalInfo += airport.city
    if airport.hasOwnProperty('state') && airport.state != ''
      additionalInfo += ', ' + airport.state
    if airport.hasOwnProperty('countryName') && airport.countryName != ''
      additionalInfo += ', ' + airport.countryName
    return additionalInfo
  isExploreMode: () ->
    mode = Session.get(GritsConstants.SESSION_KEY_MODE)
    if _.isUndefined(mode)
      return false
    else
      if mode == GritsConstants.MODE_EXPLORE
        return true
      else
        return false
  isAnalyzeMode: () ->
    mode = Session.get(GritsConstants.SESSION_KEY_MODE)
    if _.isUndefined(mode)
      return false
    else
      if mode == GritsConstants.MODE_ANALYZE
        return true
      else
        return false
  simPas: () ->
    if _.isUndefined(Template.instance().simPas)
      return 0
    else
      return Template.instance().simPas.get()
  startDate: () ->
    if _.isUndefined(Template.instance().startDate)
      return ''
    else
      return Template.instance().startDate.get()
  endDate: () ->
    if _.isUndefined(Template.instance().endDate)
      return ''
    else
      return Template.instance().endDate.get()
  departures: () ->
    if _.isUndefined(Template.instance().departures)
      return []
    else
      return Template.instance().departures.get()
  paths: () ->
    if _.isUndefined(Template.instance().paths)
      return []
    else
      paths = Template.instance().paths.get()
      return Template.instance().paths.get()
  getPathThroughputColor: (path) ->
    if _.isUndefined(path)
      return ''
    layerGroup = GritsLayerGroup.getCurrentLayerGroup()
    return layerGroup.getPathLayer()._getNormalizedColor(path)
})

Template.gritsDataTable.onCreated ->
  # initialize reactive-var to hold reference to the paths, nodes, and heatmap data
  this.paths = new ReactiveVar([])
  this.heatmaps = new ReactiveVar([])
  this.simId = null
  this.simPas = new ReactiveVar(null)
  this.startDate = new ReactiveVar(null)
  this.endDate = new ReactiveVar(null)
  this.departures = new ReactiveVar([])

  # Public API
  Template.gritsDataTable.highlightPathTableRow = highlightPathTableRow

Template.gritsDataTable.onRendered ->
  self = this

  # get the map instance
  self.map = Template.gritsMap.getInstance()

  # get the heatmap layer
  heatmapLayerGroup = self.map.getGritsLayerGroup(GritsConstants.HEATMAP_GROUP_LAYER_ID)
  self.heatmapLayer = heatmapLayerGroup.find(GritsConstants.HEATMAP_LAYER_ID)

  Tracker.autorun ->
    # determine the current layer group
    mode = Session.get(GritsConstants.SESSION_KEY_MODE)
    layerGroup = GritsLayerGroup.getCurrentLayerGroup()
    departures = GritsFilterCriteria.departures.get()
    # clear the datatable if departures == 0
    if departures.length == 0
      self.paths.set([])
      self.simPas.set(0)
      self.startDate.set('')
      self.endDate.set('')
      self.departures.set([])
      _tablesChanged.set(true)
      return

    # update the table reactively to the current visible paths
    if mode == GritsConstants.MODE_ANALYZE
      # if analyze mode; default sort by occurrances
      data = layerGroup.getPathLayer().visiblePaths.get()
      if _.isEmpty(data)
        self.paths.set([])
      else
        sorted = _.sortBy(data, (path) ->
          return path.occurrances * -1
        )
        self.paths.set(sorted)
    else
      # default sort by throughput
      data = layerGroup.getPathLayer().visiblePaths.get()
      if _.isEmpty(data)
        self.paths.set([])
      else
        sorted = _.sortBy(data, (path) ->
          return path.throughput * -1
        )
        self.paths.set(sorted)
    _tablesChanged.set(true)

  Tracker.autorun ->
    # what is the current simId
    simIds = Template.gritsSearch.simIds.get()
    if simIds.length == 0
      return
    Meteor.call('findSimulationBySimId', simIds[0], (err, simulation) ->
      if err
        console.error(err)
        return
      self.simPas.set(simulation.get('numberPassengers'))
      self.startDate.set(moment(simulation.get('startDate')).format('MM/DD/YYYY'))
      self.endDate.set(moment(simulation.get('endDate')).format('MM/DD/YYYY'))
      token = simulation.get('departureNode')
      self.departures.set([_.find(Meteor.gritsUtil.airports, (a) -> a._id == token)])
      self.simId = simulation.get('simId')
    )

  Tracker.autorun ->
    if _tablesChanged.get()
      _tablesChanged.set(false)
      $("#analyzeTable").tablesorter().trigger('update')
      $("#exploreTable").tablesorter().trigger('update')
