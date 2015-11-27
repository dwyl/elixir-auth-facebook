var env         = require('env2')('.env');
var querystring = require('querystring');
var https       = require('https');

var Hapi        = require('hapi');
var server      = new Hapi.Server();

server.connection({
  host: '0.0.0.0',
  port: Number(process.env.PORT)
});

server.route([
  { method: 'GET',
    path: '/',
    handler: function(request, reply) {
      var redirectUri = 'http://0.0.0.0:8000/login';
      var url = 'https://www.facebook.com/dialog/oauth?client_id=' + process.env.FACEBOOK_APP_ID + '&redirect_uri=' + redirectUri;
      var btn = '<a href="' + url + '"><img src="http://i.stack.imgur.com/pZzc4.png"></a>';
      reply(btn);
    }
  },
  { method: 'GET', 
    path: '/login',
    handler: function(request, reply) {
      console.log(request.query);
      var body = createAccessTokenRequestBody(request.query.code);
      var getAccessTokenOpts = {
        hostname: 'graph.facebook.com',
        path: '/v2.3/oauth/access_token?' + body,
        method: 'GET'
      };
      httpsRequest(getAccessTokenOpts, function(accessToken) {
        console.log(accessToken);
        reply('<img src="http://pix.iemoji.com/images/emoji/apple/8.3/256/light-brown-thumbs-up-sign.png">');
      });
    }
  }
]);

function httpsRequest(options, callback) {
  var request = https.request(options, function(response) {
    var body = '';
    response.on('data', function(chunk) {
        body += chunk;
    });
    response.on('end', function() {
      callback(body);
    });
  });
  request.end();
}

function createAccessTokenRequestBody(code) {
  var qs = querystring.stringify({
    client_id: process.env.FACEBOOK_APP_ID,
    redirect_uri: 'http://0.0.0.0:8000/login',
    client_secret: process.env.FACEBOOK_APP_SECRET,
    code: code
  });
  return qs;
}

server.start(function() {
  console.log("Server listening on " + server.info.uri);
});
