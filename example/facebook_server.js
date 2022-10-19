var Hapi = require("hapi");
var server = new Hapi.Server();
var assert = require("assert");

var facebookAuth = require("../lib/index.js");

server.connection({
  host: "0.0.0.0",
  port: Number(process.env.PORT),
});

var facebookAuthRequestUrl = "/authfacebook";

server.register(
  {
    register: facebookAuth,
    options: {
      handler: require("./facebook_oauth_handler"),
      redirectUri: "/facebooklogin",
      tokenRequestPath: facebookAuthRequestUrl,
    },
  },
  function (err) {
    assert(!err, "failed to load plugin");
  }
);

var createLoginButton = function () {
  return (
    '<a href="' +
    facebookAuthRequestUrl +
    '"><img src="http://i.stack.imgur.com/pZzc4.png"></a>'
  );
};

server.route({
  path: "/facebook",
  method: "GET",
  handler: function (request, reply) {
    reply(createLoginButton());
  },
});

server.start(function () {
  console.log("Server listening on " + server.info.uri);
});

module.exports = server;
