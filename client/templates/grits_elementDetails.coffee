# shows the path tab
showPath = () ->
  $('.element-details').show()
  $('.element-details-nav a[href="#pathDetails"]').tab('show')

# shows the node tab
showNode = () ->
  $('.element-details').show()
  $('.element-details-nav a[href="#nodeDetails"]').tab('show')

Template.gritsElementDetails.events
  'click .element-details-close': (e) ->
    $('.element-details').hide()

Template.gritsElementDetails.helpers({
  node: () ->
    if _.isUndefined(Template.instance().node)
      return {}
    else
      return Template.instance().node.get()
  path: () ->
    if _.isUndefined(Template.instance().path)
      return {}
    else
      return Template.instance().path.get()
  pathWeight: (path) ->
    if _.isUndefined(path) || _.isNull(path)
      return ''
    return +(path.weight).toFixed(2)
  normalized: (obj) ->
    if _.isUndefined(obj) || _.isNull(obj)
      return ''
    if !obj.hasOwnProperty('normalizedPercent')
      return ''
    return +(obj.normalizedPercent).toFixed(2)
  nodeTotalThroughput: (node) ->
    if _.isUndefined(node) || _.isNull(node)
      return ''
    return node.incomingThroughput + node.outgoingThroughput
})

Template.gritsElementDetails.onCreated ->
  self = this
  self.path = new ReactiveVar(null)
  self.node = new ReactiveVar(null)
  #Public API
  Template.gritsElementDetails.showPath = showPath
  Template.gritsElementDetails.showNode = showNode

Template.gritsElementDetails.onRendered ->
  self = this
  $('.element-details').hide()
  #store reference to the map and layer instances
  self.map = Template.gritsMap.getInstance()

  # update the currentPath
  Tracker.autorun ->
    # determine the current layer group
    mode = Session.get(GritsConstants.SESSION_KEY_MODE)
    layerGroup = GritsLayerGroup.getCurrentLayerGroup()
    p1 = layerGroup.getPathLayer().currentPath.get()
    p2 = self.path.get()
    if _.isEqual(p1, p2)
      return
    self.path.set(p1)
    showPath()
    return

  # update the currentNode
  Tracker.autorun ->
    # determine the current layer group
    mode = Session.get(GritsConstants.SESSION_KEY_MODE)
    layerGroup = GritsLayerGroup.getCurrentLayerGroup()
    n1 = layerGroup.getNodeLayer().currentNode.get()
    n2 = self.node.get()
    if _.isEqual(n1, n2)
      return
    self.node.set(n1)
    if !_.isNull(n1)
      showNode()
    return
