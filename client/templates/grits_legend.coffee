

Template.gritsLegend.events({
  'slide': (event, template) ->
    $slider = $(event.target)
    name = $slider.data('slider-name')
    val = $slider.slider('getValue')
    map = Template.gritsMap.getInstance()
    layer = map.getGritsLayer(name)
    layer.filterByMinMaxThroughput(val[0], val[1])
})

Template.gritsLegend.helpers({
  pathLayerName: () ->
    return 'Paths'
  nodeLayerName: () ->
    return 'Nodes'
  nodeColorScale: (k) ->
    num = parseInt(k, 10)
    return GritsNodeLayer.colorScale[num]
  pathColorScale: (k) ->
    num = parseInt(k, 10)
    return GritsPathLayer.colorScale[num]
})

Template.gritsLegend.onCreated ->
  #Public API

Template.gritsLegend.onRendered ->
  self = this
  $('.slider').slider()