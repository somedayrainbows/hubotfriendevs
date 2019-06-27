# Description:
#   Get a NOICE gif
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot noice
#
# Author:
#  Erin

module.exports = (robot) ->

  guid = ->
    s4 = ->
      Math.floor((1 + Math.random()) * 0x10000).toString(16).substring 1
    s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4()

  img = 'http://media.giphy.com/media/jADK27n0qKxW0/giphy.gif?' + guid()

  robot.hear /noo?ice/i, (msg)->
    msg.send img
