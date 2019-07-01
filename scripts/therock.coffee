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

module.exports = (robot) ->
  guid = ->
    s4 = ->
      Math.floor((1 + Math.random()) * 0x10000).toString(16).substring 1
    s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4()

  img = 'https://media.giphy.com/media/QLvRBqfLXCphu/giphy.gif?' + guid()

  robot.hear /rock/i, (msg)->
    msg.send img
