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
    'fuatsengul:leaflet@1.0.1',
    'jagi:astronomy@0.12.0',
    'jagi:astronomy-validators@0.10.8',
    'mizzao:autocomplete@0.5.1',
    'peerlibrary:async@0.9.2_1',
    'twbs:bootstrap@3.3.4',
    'mquandalle:stylus',
    'fortawesome:fontawesome',
    'grits:grits-net-mapper@0.2.2',
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
    'client/grits_util.coffee',
    'client/templates/map.html',
    'client/templates/map.coffee',
    'client/templates/legend.html',
    'client/templates/filter.html',
    'client/templates/filter.coffee',
    'client/templates/nodeDetails.html',
    'client/templates/pathDetails.html',
    'client/subscription.coffee',
    'client/images/ajax-loader.gif'
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
    'Flights'
  ], ['client', 'server']);
});
