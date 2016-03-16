# Template.gritsDataTable
#
# When another meteor app adds grits:grits-net-meteor as a package
# Template.gritsDataTable will be available globally.
_previousPath = null # placeholder for the last clicked path
_previousMode = null # placeholder for thet last mode
_simId = new ReactiveVar(null)

# highlights the path table row
#
# @param [Object] a GritsPath object
highlightPathTableRow = (path) ->
  if not (path instanceof GritsPath)
    return
  $row = $("tr[data-id=#{path._id}]")
  # remove any previously clicked rows
  $table = $row.closest('table')
  $table.find('.activeRow').removeClass('activeRow')
  if _previousPath isnt path
    # add the active class to this row and remove any background-color
    $row.addClass('activeRow').css({ 'background-color': '' })
    # reset the previous path background-color
    if not _.isNull(_previousPath)
      $previousPath = $("tr[data-id=#{_previousPath._id}]")
    # this path becomes the previousPath
    _previousPath = path
  else
    # clicked on same path, reset the color and set _previousPath to null
    $row.css({ 'background-color': path.color })
    _previousPath = null
  return

# update the simulationProgress bar
_updateSimulationProgress = (progress) ->
  $('.simulation-progress').css({width: progress})
  return progress

_textToSortKey = (text) ->
  if text is 'Origin'
    'origin._id'
  else if text is 'Destination'
    'destination._id'
  else if text is 'Occurrences'
    'occurrences'
  else if text is 'Total Seats'
    'throughput'

Template.gritsDataTable.onCreated ->
  # initialize reactive-var to hold reference to the paths, nodes, and heatmap data
  @paths = new Meteor.Collection(null)
  @sortKey = new ReactiveVar('occurrences')
  @sortOrder = new ReactiveVar(-1)
  @heatmaps = new ReactiveVar([])
  @simId = null
  @simPas = new ReactiveVar(null)
  @startDate = new ReactiveVar(null)
  @endDate = new ReactiveVar(null)
  @departures = new ReactiveVar([])

  @_reset = =>
    @paths.remove({})
    @simPas.set(0)
    @startDate.set('')
    @endDate.set('')
    @departures.set([])
    _simId.set(null)

  # Public API
  Template.gritsDataTable.highlightPathTableRow = highlightPathTableRow
  Template.gritsDataTable.simId = _simId
  Template.gritsDataTable.reset = @_reset


Template.gritsDataTable.onRendered ->
  # setup the clipboard for share-btn-link
  @clip = new Clipboard('.share-copy-btn')
  @clip.on('success', ->
    toastr.info(i18n.get('toastMessages.clipboard'))
    @$('.share-link-container').hide()
  )

  # get the map instance
  @map = Template.gritsMap.getInstance()

  # get the heatmap layer
  heatmapLayerGroup = @map.getGritsLayerGroup(GritsConstants.HEATMAP_GROUP_LAYER_ID)
  @heatmapLayer = heatmapLayerGroup.find(GritsConstants.HEATMAP_LAYER_ID)

  Meteor.autorun =>
    # determine the current layer group
    mode = Session.get(GritsConstants.SESSION_KEY_MODE)
    # update the table reactively to the current visible paths
    if mode == GritsConstants.MODE_ANALYZE
      # if analyze mode; default sort by occurrences
      @sortKey.set('occurrences')
    else
      @sortKey.set('throughput')
    @sortOrder.set(-1)

  # Populate the minimongo collection
  Meteor.autorun =>
    layerGroup = GritsLayerGroup.getCurrentLayerGroup()
    data = layerGroup.getPathLayer().visiblePaths.get()
    unless _.isEmpty(data)
      i = 0
      l = data.length
      while i < l
        item = data[i]
        @paths.upsert(item._id, item)
        i++

  Meteor.autorun =>
    departures = GritsFilterCriteria.departures.get()
    # clear the datatable if departures == 0
    if departures.length is 0
      @_reset()

  Meteor.autorun =>
    # what is the current simId
    simId = _simId.get()
    if _.isEmpty(simId)
      return
    Meteor.call('findSimulationBySimId', simId, (err, simulation) =>
      if err
        throw new Meteor.Error err
      @simPas.set(simulation.get('numberPassengers'))
      @startDate.set(moment(simulation.get('startDate')).format('MM/DD/YYYY'))
      @endDate.set(moment(simulation.get('endDate')).format('MM/DD/YYYY'))
      tokens = simulation.get('departureNodes')
      airports = _.filter(Meteor.gritsUtil.airports, (a) ->
        _.indexOf(tokens, a._id) >= 0)
      @departures.set(airports)
      @simId = simulation.get('simId')
    )


Template.gritsDataTable.events
  'click .share-btn': (event, template) ->
    # toggle the display of the share-link-container
    template.$('.share-link-container').slideToggle('fast')

  'click th': (event, template) ->
    element = event.currentTarget
    text = element.textContent
    sortKey = _textToSortKey(text)
    if template.sortKey.get() is sortKey
      template.sortOrder.set(-template.sortOrder.get())
    else
      template.sortKey.set(sortKey)

  'click .pathTableRow': (event, template) ->
    # get the clicked row
    $row = $(event.currentTarget)
    # find the path from template.paths using the DOM's id
    _id = $row.data('id')
    path = template.paths.findOne(_id)
    if _.isUndefined(path)
      return
    element = $('#' + path.elementID)[0]
    if _.isUndefined(element)
      return
    # simulate a click on the path
    path.eventHandlers.click(element)

  'click .exportData': (event, template) ->
    template.$('.dtHidden').show()
    fileType = $(event.currentTarget).attr("data-type")
    activeTable = template.$('.dataTableContent').find('.active').find('.table.dataTable')
    if activeTable.length
      activeTable.tableExport({type: fileType})
    template.$('.dtHidden').hide()


Template.gritsDataTable.helpers
  sorting: (text) ->
    instance = Template.instance()
    sortKey = _textToSortKey(text)
    if instance.sortKey.get() is sortKey
      if instance.sortOrder.get() > 0
        'tablesorter-headerAsc'
      else
        'tablesorter-headerDesc'
  getCurrentURL: ->
    return FlowRouter.currentURL.get()
  getNodeName: (n) ->
    if _.isUndefined(n)
      return
    if n._id.indexOf(GritsMetaNode.PREFIX) >= 0
      return n._id
    node = _.find(Meteor.gritsUtil.airports, (node) -> node._id == n._id)
    return node.name
  getNodeCity: (n) ->
    if _.isUndefined(n)
      return
    if n._id.indexOf(GritsMetaNode.PREFIX) >= 0
      return 'N/A'
    node = _.find(Meteor.gritsUtil.airports, (node) -> node._id == n._id)
    return node.city
  getNodeState: (n) ->
    if _.isUndefined(n)
      return
    if n._id.indexOf(GritsMetaNode.PREFIX) >= 0
      return 'N/A'
    node = _.find(Meteor.gritsUtil.airports, (node) -> node._id == n._id)
    return node.state
  getNodeCountry: (n) ->
    if _.isUndefined(n)
      return
    if n._id.indexOf(GritsMetaNode.PREFIX) >= 0
      return 'N/A'
    node = _.find(Meteor.gritsUtil.airports, (node) -> node._id == n._id)
    return node.countryName
  simulationProgress: ->
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
  isExploreMode: ->
    mode = Session.get(GritsConstants.SESSION_KEY_MODE)
    if _.isUndefined(mode)
      return false
    else
      if mode is GritsConstants.MODE_EXPLORE
        return true
      else
        return false
  isAnalyzeMode: ->
    mode = Session.get(GritsConstants.SESSION_KEY_MODE)
    if _.isUndefined(mode)
      return false
    else
      if mode == GritsConstants.MODE_ANALYZE
        return true
      else
        return false
  simPas: ->
    if _.isUndefined(Template.instance().simPas)
      return 0
    else
      return Template.instance().simPas.get()
  startDate: ->
    if _.isUndefined(Template.instance().startDate)
      return ''
    else
      return Template.instance().startDate.get()
  endDate: ->
    if _.isUndefined(Template.instance().endDate)
      return ''
    else
      return Template.instance().endDate.get()
  departures: ->
    if _.isUndefined(Template.instance().departures)
      return []
    else
      return Template.instance().departures.get()
  hasPaths: ->
    Template.instance().paths.find().count() > 0
  paths: ->
    instance = Template.instance()
    _sort = {}
    _sort[instance.sortKey.get()] = instance.sortOrder.get()
    # always back the sorting by the amount of occurences
    if instance.sortKey.get() isnt 'occurrences'
      _sort['occurrences'] = -1
    Template.instance().paths.find({}, {sort: _sort})
  getPathThroughputColor: (path) ->
    if _.isUndefined(path)
      return ''
    layerGroup = GritsLayerGroup.getCurrentLayerGroup()
    return layerGroup.getPathLayer()._getNormalizedColor(path)
