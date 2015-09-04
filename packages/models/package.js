Package.describe({
  name: 'grits-net-meteor:models',
  version: '0.0.1',
  summary: 'Models for grits-net-meteor',
  git: ''
});

Package.onUse(function(api) {
  api.versionsFrom('1.1.0.3');  
  api.use('coffeescript');
  api.use('jagi:astronomy@0.12.0');
  api.use('jagi:astronomy-validators@0.10.8');
  api.use('mongo');
  api.addFiles('flights.coffee', ['client', 'server']);
  api.addFiles('airports.coffee', ['client', 'server']);
  api.export(['Airport', 'Airports'], ['client', 'server']);
  api.export(['Flight', 'Flights'], ['client', 'server']);
});

Package.onTest(function(api) {
  api.use('tinytest');
  api.use('coffeescript');
});