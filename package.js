Package.describe({
  summary: 'Exposes {{ >map }} template as the interface to grits-net-mapper',
  version: '0.0.1',
  name: 'grits:grits-net-meteor',
  git: '',
});
Package.on_use(function(api){
  api.use();
    api.use();
  api.use([
    'coffeescript',
    'mongo',
    'jagi:astronomy@0.12.0',
    'jagi:astronomy-validators@0.10.8',
    'grits:grits-net-mapper'
  ]);
  api.use([
    'underscore',
    'templating',
    'minimongo',
    'session',
    'tracker'
  ], 'client');
  api.add_files([
    'client/stylesheets/main.css',
    'client/templates/filter.html',
    'client/templates/map.html',
    'client/templates/nodeDetails.html',
    'client/templates/pathDetails.html',
    'client/templates/map.coffee',
    'client/subscriptions.coffee'
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
    'Airports'
  ], ['client', 'server']);
  api.export([
    'Flight',
    'Flights'
  ], ['client', 'server']);
});
