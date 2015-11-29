var authHandler = function(request, reply, accessToken) {
  reply('Your token: ' + accessToken);
};

module.exports = authHandler;
