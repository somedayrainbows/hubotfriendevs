# Description:
#   Get a gif of The Rock
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot rock
#
# Author:
#  Erin

module.exports = function(robot) {
  const guid = function() {
    const s4 = () => Math.floor((1 + Math.random()) * 0x10000).toString(16).substring(1);
    return s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4();
  };

  const img = 'https://media.giphy.com/media/QLvRBqfLXCphu/giphy.gif?' + guid();

  return robot.hear(/rock/i, msg => msg.send(img));
};
