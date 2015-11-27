var Hapi   = require('hapi');
var server = new Hapi.Server();

server.connection({
  host: '0.0.0.0',
  port: Number(process.env.PORT)
});

server.route([

  { method: 'GET',
    path: '/',
    handler: function (request, reply) {
      var url = 'http://google.com';
      var btn = '<a href="' + url + '"><img src="http://i.stack.imgur.com/pZzc4.png"></a>'
      reply(btn)
    }
  }
]);

server.start(function () {
  console.log("Server listening on " + server.info.uri);
});
