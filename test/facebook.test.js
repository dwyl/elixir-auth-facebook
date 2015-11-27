var test = require('tape');

var server = require('../example/facebook_server.js');

test('our first test!', function(t) {
  var options = {
    method: 'GET',
    url: '/facebook'
  };
  server.inject(options, function(response) {
    t.equal(response.statusCode, 200, 'woop')
    setTimeout(function() {
      server.stop(t.end);
    }, 100);
  });
})
