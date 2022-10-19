var env = require("env2")(".env");
var querystring = require("querystring");
var https = require("https");

var createAccessTokenQuery = function (request, server, options) {
  var query = querystring.stringify({
    client_id: process.env.FACEBOOK_APP_ID,
    redirect_uri: server.info.uri + options.redirectUri,
    client_secret: process.env.FACEBOOK_APP_SECRET,
    code: request.query.code,
  });
  return query;
};

var createAccessTokenReqestOpts = function (request, server, options) {
  var accessTokenQuery = createAccessTokenQuery(request, server, options);
  return {
    hostname: "graph.facebook.com",
    path: "/v2.3/oauth/access_token?" + accessTokenQuery,
    method: "GET",
  };
};

var getBody = function (response, callback) {
  var body = "";
  response.on("data", function (chunk) {
    body += chunk;
  });
  response.on("end", function () {
    callback(body);
  });
};

var httpsRequest = function (options, callback) {
  var request = https.request(options, function (response) {
    getBody(response, callback);
  });
  request.end();
};

var redirectHandler = function (request, reply, server, options) {
  var requestOpts = createAccessTokenReqestOpts(request, server, options);
  httpsRequest(requestOpts, function (accessTokenData) {
    var token = JSON.parse(accessTokenData).access_token;
    options.handler(request, reply, token);
  });
};

function createFacebookAuthReqUrl(server, redirectUri) {
  host = "https://www.facebook.com";
  path =
    "/dialog/oauth?" +
    querystring.stringify({
      client_id: process.env.FACEBOOK_APP_ID,
      redirect_uri: server.info.uri + redirectUri,
    });
  return host + path;
}

var authReqHandler = function (request, reply, server, options) {
  reply.redirect(createFacebookAuthReqUrl(server, options.redirectUri));
};

exports.register = function (server, options, next) {
  server.route([
    {
      method: "GET",
      path: options.tokenRequestPath,
      handler: function (request, reply) {
        authReqHandler(request, reply, server, options);
      },
    },
    {
      method: "GET",
      path: options.redirectUri,
      handler: function (request, reply) {
        redirectHandler(request, reply, server, options);
      },
    },
  ]);
  next();
};

exports.register.attributes = {
  name: "hapi-auth-facebook",
};
