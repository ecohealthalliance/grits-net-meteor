Package.describe({
  summary: 'Exposes {{ >gritsMap }} template as the interface to grits-net-mapper',
  version: '0.0.1',
  name: 'grits:grits-net-meteor',
  git: ''
});
Package.on_use(function(api){
  // client and server packages
  api.use([
    'underscore',
    'coffeescript',
    'mongo',
    'reactive-var',
    'reactive-dict',
    'jagi:astronomy@1.2.2',
    'jagi:astronomy-validators@1.1.1',
    'peerlibrary:async@0.9.2_1',
    'twbs:bootstrap@3.3.5',
    'mquandalle:stylus@1.1.1',
    'jparker:crypto-md5@0.1.1',
    'bevanhunt:leaflet@0.3.18',
    'brylie:leaflet-heat@0.1.0',
    'fortawesome:fontawesome@4.4.0',
    'd3js:d3@3.5.5',
    'fourq:typeahead@1.0.0',
    'ajduke:bootstrap-tokenfield@0.5.0',
    'flawless:meteor-toastr@1.0.1',
    'meteorhacks:aggregate@1.3.0',
    'momentjs:moment@2.10.6',
    'kidovate:bootstrap-slider@0.0.5',
    'momentjs:moment@2.10.6',
    'grits:grits-net-mapper@0.2.2'
  ]);
  // client only packages
  api.use([
    'templating',
    'minimongo',
    'session',
    'tracker'
  ], 'client');
  // client-side only files
  api.add_files([
    'client/stylesheets/main.styl',
    'client/lib/L.D3SvgOverlay.min.js',
    'client/lib/tableExport.min.js',
    'client/grits_util.coffee',
    'client/layers/grits_nodes.coffee',
    'client/layers/grits_paths.coffee',
    'client/layers/grits_heatmap.coffee',
    'client/models/grits_filter_criteria.coffee',
    'client/templates/header.html',
    'client/templates/grits_dataTable.html',
    'client/templates/grits_dataTable.coffee',
    'client/templates/grits_map.html',
    'client/templates/grits_map.coffee',
    'client/templates/grits_filter.html',
    'client/templates/grits_filter.coffee',
    'client/templates/grits_legend.html',
    'client/templates/grits_legend.coffee',
    'client/templates/nodeDetails.html',
    'client/templates/pathDetails.html',
    'client/subscription.coffee'
  ], 'client');

  api.addAssets([
    'client/images/flirt.png',
  ], 'client');

  // both client and server files
  api.add_files([
    'models/airports.coffee',
    'models/flights.coffee',
    'models/heatmaps.coffee'
  ],['client', 'server']);
  //server-side only files
  api.add_files([
    'server/publications.coffee'
  ], 'server');
  //public API, client and server
  api.export([
    'Airport',
    'Airports',
    'Flight',
    'Flights',
    'Heatmap',
    'Heatmaps',
    'GritsFilterCriteria',
    'GritsControl',
    'GritsMap',
    'GritsHeatmapLayer',
    'GritsNodeLayer',
    'GritsPathLayer'
  ], ['client', 'server']);
});
