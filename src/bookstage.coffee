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
#   bookstage book [env] [hours] - Book the staging server and optionally specify usage time. Default is 1 hour.
#   bookstage cancel [env] - Cancel the current booking
#   bookstage add [env] - Add a new staging to the list of available staging servers
#
# Author:
#   tinifni, nathanhoel

class Message
  constructor: (env, hours) ->
    @env = env
    @hours = hours
  getEnv: ->
    if @env == undefined
      return 'staging'
    else
      return @env

  gethours: ->
    if @hours == undefined
      return 1
    else
      return Number(@hours)

bookEnv = (data, user, hours) ->
  fixExpires(data)
  if data.user != user && new Date() < data.expires
    return false
  else
    data.user = user
    data.expires = new Date()
  data.expires = new Date(data.expires.getTime() + hours * 1000 * 60 * 60)

status = (env, data) ->
  fixExpires(data)
  return "#{env} is free for use." if data.expires < new Date()

  minutes = Math.ceil((data.expires - new Date())/(60*1000))
  time = "#{minutes} minutes"
  if minutes > 120
    hours = Math.ceil(minutes/60)
    time = "#{hours} hours"
  return "#{data.user} has #{env} booked for the next #{time}."

cancelBooking = (data) ->
  data.expires = new Date(0)

fixExpires = (data) ->
  data.expires = new Date(data.expires) if typeof data.expires is 'string'

module.exports = (robot) ->
  robot.brain.on 'loaded', =>
    robot.brain.data.bookstage ||= {}

  robot.respond /bookstage book\s?([A-Za-z]+)*\s?(\d+)*/i, (msg) ->
    message = new Message(msg.match[1], msg.match[2])
    env = message.getEnv()
    hours = message.gethours()

    bookEnv(robot.brain.data.bookstage[env], msg.message.user.name, hours)
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

    robot.brain.data.bookstage[env] ||= { user: "initial", expires: new Date(0) }
    msg.send status(env, robot.brain.data.bookstage[env])

  robot.respond /bookstage remove\s?([A-Za-z]+)*/i, (msg) ->
    message = new Message(msg.match[1])
    env = message.getEnv()

    robot.brain.data.bookstage[env].del
    msg.send "Deleted #{env}"

  robot.respond /bookstage list/i, (msg) ->
    for env, value of robot.brain.data.bookstage
      msg.send status(env, value)
