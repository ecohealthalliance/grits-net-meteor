Template.gritsMapSidebar.events
  'click #sidebar-plus-button': (event) ->
    Template.gritsMap.getInstance().zoomIn()
  'click #sidebar-minus-button': (event) ->
    Template.gritsMap.getInstance().zoomOut()
