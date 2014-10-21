Package.describe({
  summary: "Sweet Highcharts for Mongo queries.",
  version: "1.0.1",
  git: 'https://github.com/maxko87/meteor-mongo-graph'
});

Package.onUse(function(api) {
  api.versionsFrom('METEOR@0.9.0.1');
  api.use( ['jquery', 'coffeescript', 'underscore', 'mrt:highcharts@0.1.0'] );
  api.use( ['meteorhacks:npm@1.0.0'], 'server' );

  api.addFiles('main.coffee'); 
  
  if (typeof api.export !== 'undefined') {
    api.export(['MongoGraph']);
  }

});