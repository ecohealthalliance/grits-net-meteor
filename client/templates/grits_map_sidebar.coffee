Template.gritsMapSidebar.events
  'click #sidebar-plus-tab': (event) ->
    Template.gritsMap.getInstance().zoomIn()
  'click #sidebar-minus-tab': (event) ->
    Template.gritsMap.getInstance().zoomOut()
