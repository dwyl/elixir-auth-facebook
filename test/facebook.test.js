var test = require('tape');
var nock = require('nock');
var dir = __dirname.split('/')[__dirname.split('/').length - 1];
var file = dir + __filename.replace(__dirname, '') + ' > ';

var server = require('../example/facebook_server.js');

test(file + 'our first test!', function(t) {
  var options = {
    method: 'GET',
    url: '/facebook'
  };
  server.inject(options, function(response) {
    t.equal(response.statusCode, 200, 'woop');
    setTimeout(function() {
      server.stop(t.end);
    }, 100);
  });
});

var mockToken = {
  "access_token": "abcdefghijklmnopqrstuvwxyzDUMMY_TOKEN1234567890",
  "token_type": "bearer",
  "expires_in": 5183971
};



test(file + 'first nock test', function(t) {
  var options = {
    method: 'GET',
    url: '/facebook'
  };
  var nock = require('nock');
  var scope = nock('https://graph.facebook.com')
    .get('/v2.3/oauth/access_token?')
    .reply(200, mockToken);
  server.inject(options, function(response) {
    t.equal(response.statusCode, 200, "Mock Test Working!");
    server.stop(t.end);
  });

});
