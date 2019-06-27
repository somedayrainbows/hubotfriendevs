# Description:
#   Track arbitrary karma
#
# Dependencies:
#   None
#
# Configuration:
#   KARMA_ALLOW_SELF
#
# Commands:
#   hubot karma create <thing> - create a thing that has karma
#   hubot karma empty <thing> - empty a thing's karma
#   <thing>++ - give thing some karma
#   <thing>-- - take away some of thing's karma
#   hubot karma <thing> - check thing's karma (if <thing> is omitted, show the top 5)
#   hubot karma best - show the top 5
#   hubot karma worst - show the bottom 5

class Karma

  constructor: (@robot) ->
    @cache = {}

    @increment_responses = [
      "+1!", "got some karma! Woohoo!", "is so loved. You go, girl.", "leveled up! Yassss!"
    ]

    @decrement_responses = [
      "lost some karma! So sad.", "has been downgraded.", "lost a level. Ouch!"
    ]

    @robot.brain.on 'loaded', =>
      if @robot.brain.data.karma
        @cache = @robot.brain.data.karma

  exists: (thing) ->
    (thing of @cache)

  create: (thing) ->
    @cache[thing] ?= 0
    @robot.brain.data.karma = @cache

  kill: (thing) ->
    delete @cache[thing]
    @robot.brain.data.karma = @cache

  increment: (thing) ->
    @cache[thing] ?= 0
    @cache[thing] += 1
    @robot.brain.data.karma = @cache

  decrement: (thing) ->
    @cache[thing] ?= 0
    @cache[thing] -= 1
    @robot.brain.data.karma = @cache

  adjust: (thing, ammount) ->
    @cache[thing] ?= 0
    @cache[thing] += ammount
    @robot.brain.data.karma = @cache

  incrementResponse: ->
    @increment_responses[Math.floor(Math.random() * @increment_responses.length)]

  decrementResponse: ->
    @decrement_responses[Math.floor(Math.random() * @decrement_responses.length)]

  selfDeniedResponses: (name) ->
    @self_denied_responses = [
      "You can't self-award karma. Who do you think you are, Abraham?!",
      "Um, no.",
      "Nope. Try getting someone else to give you some karma, #{name}."
    ]

  exists: (thing) ->
    Object.keys(@cache).indexOf(thing) != -1

  get: (thing) ->
    k = if @cache[thing] then @cache[thing] else 0
    return k

  sort: ->
    s = []
    for key, val of @cache
      s.push({ name: key, karma: val })
    s.sort (a, b) -> b.karma - a.karma

  top: (n = 10) ->
    sorted = @sort()
    sorted.slice(0, n)

  bottom: (n = 10) ->
    sorted = @sort()
    sorted.slice(-n).reverse()

  cleanSubject: (subject) ->
    # remove any prefix characters (e.g. @, ", ', etc.)
    subject.trim().replace(/^[^a-z]+/, '').replace(/:$/, '')

module.exports = (robot) ->
  karma = new Karma robot
  allow_self = process.env.KARMA_ALLOW_SELF or false

  robot.hear /(@[^@+:]+|[^-+:\s]*)[:\s]*(\+\+|--)/g, (msg) ->
    output = []
    for subject in msg.match
      user = msg.message.user.name.toLowerCase()
      subject = subject.trim()
      increasing = subject[-2..-1] == "++"
      subject = karma.cleanSubject(subject[0..-3].toLowerCase())
      if subject == ''
        continue

      if allow_self is false and user == subject
        output.push msg.random karma.selfDeniedResponses(msg.message.user.name)
        continue

      if !karma.exists subject
        output.push "Karma does not exist for '#{subject}'. Use `#{robot.name} karma create #{subject}` to make it right."
        continue

      if increasing
        karma.increment subject
        output.push "#{subject} #{karma.incrementResponse()} (Karma: #{karma.get(subject)})"
      else
        karma.decrement subject
        output.push "#{subject} #{karma.decrementResponse()} (Karma: #{karma.get(subject)})"
    if output.length > 0
      msg.send output.join '\n'

  robot.respond /karma create ?(@[^@+:]+|[^-+:\s]*)$/i, (msg) ->
    subject = karma.cleanSubject(msg.match[1].toLowerCase())

    if karma.exists subject
      msg.send "Karma already exists for #{subject}"
      return

    karma.create subject
    msg.send "#{subject} is now ready to receive karma! Use `#{subject}++` and `#{subject}--` to give and take karma."

  robot.respond /karma empty ?(@[^@+:]+|[^-+:\s]*)$/i, (msg) ->
    subject = karma.cleanSubject(msg.match[1].toLowerCase())
    karma.kill subject
    msg.send "#{subject}'s karma has been scattered to the winds."

  robot.respond /karma( best)?$/i, (msg) ->
    verbiage = ["The Best"]
    for item, rank in karma.top()
      verbiage.push "#{rank + 1}. #{item.name} - #{item.karma}"
    msg.send verbiage.join("\n")

  robot.respond /karma worst$/i, (msg) ->
    verbiage = ["The Worst"]
    for item, rank in karma.bottom()
      verbiage.push "#{rank + 1}. #{item.name} - #{item.karma}"
    msg.send verbiage.join("\n")

  robot.respond /karma (@[^@+:]+|[^-+:\s]*)$/i, (msg) ->
    match = karma.cleanSubject(msg.match[1].toLowerCase())
    if match != "best" && match != "worst" && match.substr(0, 6) != "create" && match.substr(0, 5) != "empty"
      if karma.exists(match)
        msg.send "\"#{match}\" has #{karma.get(match)} karma."
      else
        msg.send "Karma does not exist for '#{match}'. Use `#{robot.name} karma create #{match}` to make it right."
