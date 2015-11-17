Package.describe({
  summary: 'Exposes {{ >map }} template as the interface to grits-net-mapper',
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
    'ajduke:bootstrap-tokenfield'
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
    'client/grits_nodes.coffee',
    'client/grits_paths.coffee',
    'client/grits_util.coffee',
    'client/grits_heatmap.coffee',
    'client/templates/map.html',
    'client/templates/map.coffee',
    'client/templates/legend.html',
    'client/templates/filter.html',
    'client/templates/filter.coffee',
    'client/templates/nodeDetails.html',
    'client/templates/pathDetails.html',
    'client/subscription.coffee'
  ], 'client');
  
  api.addAssets([
    'client/images/ajax-loader.gif',
    'client/images/marker-icon-282828.svg',
    'client/images/marker-icon-383838.svg',
    'client/images/marker-icon-484848.svg',
    'client/images/marker-icon-585858.svg',
    'client/images/marker-icon-787878.svg',
    'client/images/marker-icon-686868.svg',
    'client/images/marker-icon-888888.svg',
    'client/images/marker-icon-989898.svg',
    'client/images/marker-icon-A8A8A8.svg',
    'client/images/marker-icon-B8B8B8.svg'
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
    'GritsHeatmap',
    'GritsNode',
    'GritsNodeLayer',
    'GritsPath',
    'GritsPaths',
    'GritsPathLayer'
  ], ['client', 'server']);
});
