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
    'deps',
    'reactive-var',
    'reactive-dict',
    'fuatsengul:leaflet',
    'jagi:astronomy',
    'jagi:astronomy-validators',
    'mizzao:autocomplete',
    'peerlibrary:async',
    'twbs:bootstrap',
    'mquandalle:stylus',
    'fortawesome:fontawesome',
    'jparker:crypto-md5',
    'grits:grits-net-mapper@0.2.2'
  ]);
  // client only packages
  api.use([
    'templating',
    'minimongo',
    'session',
  ], 'client');
  // client-side only files
  api.add_files([
    'client/stylesheets/main.styl',
    'client/lib/leaflet-heat.js',
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
  //client static assets
  api.addAssets('client/images/ajax-loader.gif', 'client');
  //public API
  api.export([
    'Airport',
    'Airports',
    'Flight',
    'Flights',
    'GritsHeatmap'
  ], ['client', 'server']);
});
