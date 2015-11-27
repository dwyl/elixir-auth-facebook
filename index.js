var env    = require('env2')('.env');
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
      var redirectUri = 'http://0.0.0.0:8000/login';
      var url = 'https://www.facebook.com/dialog/oauth?client_id=' + process.env.FACEBOOK_APP_ID + '&redirect_uri=' + redirectUri;
      var btn = '<a href="' + url + '"><img src="http://i.stack.imgur.com/pZzc4.png"></a>';
      reply(btn);
    }
  },
  { method: 'GET', // yeah?
    path: '/login',
    handler: function (request, reply) {
      reply("login successful!!");
    }
  }
]);

server.start(function () {
  console.log("Server listening on " + server.info.uri);
});
