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
    'jagi:astronomy',
    'jagi:astronomy-validators',
    'peerlibrary:async',
    'twbs:bootstrap',
    'mquandalle:stylus',
    'jparker:crypto-md5',
    'bevanhunt:leaflet@0.3.18',
    'brylie:leaflet-heat@0.1.0',
    'fortawesome:fontawesome',
    'd3js:d3',
    'sergeyt:typeahead',
    'ajduke:bootstrap-tokenfield',
    'grits:grits-net-mapper'
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
    'client/grits_util.coffee',
    'client/layers/grits_nodes.coffee',
    'client/layers/grits_paths.coffee',    
    'client/layers/grits_heatmap.coffee',
    'client/models/grits_filter_criteria.coffee',
    'client/templates/grits_map.html',
    'client/templates/grits_map.coffee',
    'client/templates/legend.html',
    'client/templates/grits_filter.html',
    'client/templates/grits_filter.coffee',
    'client/templates/nodeDetails.html',
    'client/templates/pathDetails.html',
    'client/subscription.coffee'
  ], 'client');
  
  api.addAssets([
    'client/images/ajax-loader.gif'
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
  //public API
  api.export([
    'Airport',
    'Airports',
    'Flight',
    'Flights',
    'Heatmap',
    'Heatmaps',
    'GritsFilterCriteria',
    'GritsMap',
    'GritsHeatmapLayer',
    'GritsNodeLayer',
    'GritsPathLayer'
  ], ['client', 'server']);
});
