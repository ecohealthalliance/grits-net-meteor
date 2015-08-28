Package.describe({
  name: 'treyyoder:mapper',
  version: '0.0.1',
  summary: '',
  git: '',  
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.1.0.3');  
  api.use('coffeescript');
  api.use('fuatsengul:leaflet', 'client'); 
  api.addFiles('leafnav.js', ['client']);
  api.addFiles('mapper.coffee', ['client']);
});

Package.onTest(function(api) {
  api.use('tinytest');
  api.use('treyyoder:mapper');
  api.addFiles('mapper-tests.js');
});
