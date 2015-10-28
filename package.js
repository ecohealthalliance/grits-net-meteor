Package.describe({
  summary: 'Exposes {{ >map }} template as the interface to grits-net-mapper',
  version: '0.0.1',
  name: 'grits:grits-net-meteor',
  git: '',
});
Package.on_use(function(api){
  api.use([
    'coffeescript',
    'mongo',
    'jagi:astronomy',
    'jagi:astronomy-validators',
    'mizzao:autocomplete',
    'peerlibrary:async',
    'twbs:bootstrap',
    'mquandalle:stylus',
    'fortawesome:fontawesome',
    'd3js:d3',
    'bevanhunt:leaflet',
    'reactive-var'
  ]);
  api.use([
    'underscore',
    'templating',
    'minimongo',
    'session',
    'tracker'
  ], 'client');
  api.add_files([
    'client/stylesheets/main.styl',
    'client/lib/L.D3SvgOverlay.min.js',
    'client/grits_nodes.coffee',
    'client/grits_util.coffee',
    'client/templates/map.html',
    'client/templates/map.coffee',
    'client/templates/legend.html',
    'client/templates/filter.html',
    'client/templates/filter.coffee',
    'client/templates/nodeDetails.html',
    'client/templates/pathDetails.html',
    'client/subscription.coffee',
    'client/images/ajax-loader.gif',
    'client/images/marker-icon-B8B8B8.png'
  ], 'client');
  api.add_files([
    'models/airports.coffee',
    'models/flights.coffee'
  ],['client', 'server']);
  api.add_files([
    'server/publications.coffee'
  ], 'server');
  api.export([
    'Airport',
    'Airports',
    'Flight',
    'Flights',
    'GritsNode',
    'GritsNodeLayer',
  ], ['client', 'server']);
});
