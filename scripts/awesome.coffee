# Description:
#   Get a gif when someone says awesome
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot awesome
#
# Author:
#  Erin

module.exports = (robot) ->

  guid = ->
    s4 = ->
      Math.floor((1 + Math.random()) * 0x10000).toString(16).substring 1
    s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4()

  img = 'https://media.giphy.com/media/3ohzdIuqJoo8QdKlnW/source.gif?' + guid()

  robot.hear /awesome/i, (msg)->
    msg.send img
