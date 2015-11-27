var env = require('env2')('.env');
var querystring = require('querystring');
var https = require('https');

exports.register = function(server, options, next) {
  server.route([
    {
      method: 'GET',
      path: options.tokenRequestPath,
      handler: function(request, reply) {
        reply.redirect(createFacebookAuthReqUrl(server, options.redirectUri));
      }
    },
    {
      method: 'GET',
      path: options.redirectUri,
      handler: function(request, reply) {
        console.log('options', options);
        var requestOpts = createAccessTokenReqestOpts(request, server, options);
        httpsRequest(requestOpts, function(accessTokenData) {
          var token = JSON.parse(accessTokenData).access_token;
          options.handler(request, reply, token);
        });
      }
    }
  ]);
  next();
}

exports.register.attributes = {
  name: 'hapi-auth-facebook'
};

var createAccessTokenReqestOpts = function(request, server, options) {
  var tempCode = request.query.code;
  var redirectUrl = server.info.uri + options.redirectUri;
  var query = createAccessTokenQuery(tempCode, redirectUrl);
  return {
    hostname: 'graph.facebook.com',
    path: '/v2.3/oauth/access_token?' + query,
    method: 'GET'
  };
}

function createFacebookAuthReqUrl(server, redirectUri) {
  // console.log('yo', server.info.uri);
  host = 'https://www.facebook.com';
  path = '/dialog/oauth?' + querystring.stringify({
    client_id: process.env.FACEBOOK_APP_ID,
    redirect_uri:createAbsoluteUrl(server.info.uri, redirectUri)
  });
  return host + path;
}

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

function createAccessTokenQuery(code, redirectUri) {
  var qs = querystring.stringify({
    client_id: process.env.FACEBOOK_APP_ID,
    redirect_uri: redirectUri,
    client_secret: process.env.FACEBOOK_APP_SECRET,
    code: code
  });
  return qs;
}
