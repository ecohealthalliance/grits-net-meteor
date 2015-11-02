Package.describe({
  summary: 'Exposes {{ >map }} template as the interface to grits-net-mapper',
  version: '0.0.1',
  name: 'grits:grits-net-meteor',
  git: '',
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
    'mizzao:autocomplete',
    'peerlibrary:async',
    'twbs:bootstrap',
    'mquandalle:stylus',
    'jparker:crypto-md5',
    'bevanhunt:leaflet',
    'brylie:leaflet-heat',
    'fortawesome:fontawesome',
    'd3js:d3'
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
    'client/subscription.coffee',
    'client/images/ajax-loader.gif',
    'client/images/marker-icon-282828.png',
    'client/images/marker-icon-383838.png',
    'client/images/marker-icon-484848.png',
    'client/images/marker-icon-585858.png',
    'client/images/marker-icon-787878.png',
    'client/images/marker-icon-686868.png',
    'client/images/marker-icon-888888.png',
    'client/images/marker-icon-989898.png',
    'client/images/marker-icon-A8A8A8.png',
    'client/images/marker-icon-B8B8B8.png'
  ], 'client');
  // both client and server files
  api.add_files([
    'models/airports.coffee',
    'models/flights.coffee'
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
    'GritsHeatmap',
    'GritsNode',
    'GritsNodeLayer',
    'GritsPath',
    'GritsPaths',
    'GritsPathLayer'
  ], ['client', 'server']);
});
