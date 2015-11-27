var Hapi        = require('hapi');
var server      = new Hapi.Server();

var facebookAuth = require('../lib/index.js');

server.connection({
  host: '0.0.0.0',
  port: Number(process.env.PORT)
});

server.register({ register: facebookAuth }, {
}, function (err) {
  if (err) console.log(err);
});

server.start(function() {
  console.log("Server listening on " + server.info.uri);
});
