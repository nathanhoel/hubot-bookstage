# Description:
#   Bookstage manages who is currently using your team's staging server
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   bookstage list - List all staging servers and their availability
#   bookstage who [env] - Show who has booked the staging server and how much time they have left
#   bookstage book [env] [minutes] - Book the staging server and optionally specify usage time. Default is 30min
#   bookstage cancel [env] - Cancel the current booking
#   bookstage add [env] - Add a new staging to the list of available staging servers
#
# Author:
#   tinifni, nathanhoel

class Message
  constructor: (env, minutes) ->
    @env = env
    @minutes = minutes
  getEnv: ->
    if @env == undefined
      return 'staging'
    else
      return @env

  getMinutes: ->
    if @minutes == undefined
      return 30
    else
      return Number(@minutes)

addEnv = (env) ->
  robot.brain.data.bookstage[env] ||= { user: "initial", expires: new Date(0) }

bookEnv = (data, user, minutes) ->
  return false if data.user != user && new Date() < data.expires
  unless data.user == user && new Date() < data.expires
    data.user = user
    data.expires = new Date()
  data.expires = new Date(data.expires.getTime() + minutes * 1000 * 60)

status = (env, data) ->
  return env + ' is free for use.' unless new Date() < data.expires
  data.user + ' has ' + env + ' booked for the next ' \
            + Math.ceil((data.expires - new Date())/(60*1000)) \
            + ' minutes.'

cancelBooking = (data) ->
  data.expires = new Date(0)

module.exports = (robot) ->
  robot.brain.on 'loaded', =>
    robot.brain.data.bookstage ||= {}

  robot.respond /bookstage book\s?([A-Za-z]+)*\s?(\d+)*/i, (msg) ->
    message = new Message(msg.match[1], msg.match[2])
    env = message.getEnv()
    minutes = message.getMinutes()

    bookEnv(robot.brain.data.bookstage[env], msg.message.user.name, minutes)
    msg.send status(env, robot.brain.data.bookstage[env])

  robot.respond /bookstage who\s?([A-Za-z]+)*/i, (msg) ->
    message = new Message(msg.match[1])
    env = message.getEnv()

    msg.send status(env, robot.brain.data.bookstage[env])

  robot.respond /bookstage cancel\s?([A-Za-z]+)*/i, (msg) ->
    message = new Message(msg.match[1])
    env = message.getEnv()

    cancelBooking(robot.brain.data.bookstage[env])
    msg.send status(env, robot.brain.data.bookstage[env])

  robot.respond /bookstage add\s?([A-Za-z]+)*/i, (msg) ->
    message = new Message(msg.match[1])
    env = message.getEnv()

    addEnv(env)
    msg.send status(env, robot.brain.data.bookstage[env])

  robot.respond /bookstage list/i, (msg) ->
    for env, value of robot.brain.data.bookstage
      msg.send status(env, value)
