var Hapi        = require('hapi');
var server      = new Hapi.Server();

var facebookAuth = require('../lib/index.js');

server.connection({
  host: '0.0.0.0',
  port: Number(process.env.PORT)
});

server.register({
  register: facebookAuth,
  options: {
    handler: function(request, reply, accessToken) {
      reply('Your token: ' + accessToken);
    },
    redirectUri: '/facebookLogin',
    tokenRequestPath: '/authFacebook'
  }
}, function (err) {
  if (err) console.log(err);
});

server.route({
  path: '/facebook',
  method: 'GET',
  handler: function(request, reply) {
    var btn = '<a href="' + '/authFacebook' +
      '"><img src="http://i.stack.imgur.com/pZzc4.png"></a>';
    reply(btn);
  }
})


server.start(function() {
  console.log("Server listening on " + server.info.uri);
});

module.exports = server;
