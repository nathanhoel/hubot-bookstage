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
#   hubot bookstage list - List all staging servers and their availability
#   hubot bookstage who <env> - Show who has booked the staging server and how much time they have left
#   hubot bookstage book <env> [hours] - Book the staging server and optionally specify usage time. Default is 1 hour.
#   hubot bookstage cancel <env> - Cancel the current booking
#   hubot bookstage add <env> - Add a new staging to the list of available staging servers
#
# Author:
#   tinifni, nathanhoel

HALF_HOUR_MS = 1800000

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

bookEnv = (env, data, res, hours) ->
  fixExpires(data)
  ms = hours * 1000 * 60 * 60
  if data.user != res.message.user.name && new Date() < data.expires
    return false
  else
    data.user = res.message.user.name
    data.expires = new Date()
    data.timeoutId = setTimeout () ->
      res.reply "You have 30 minutes remaining on your reservation of *#{env}*"
    , (ms - HALF_HOUR_MS)
  data.expires = new Date(data.expires.getTime() + ms)

status = (env, data) ->
  fixExpires(data)
  return "*#{env}* is free for use." if data.expires < new Date()

  minutes = Math.ceil((data.expires - new Date())/(60*1000))
  time = "#{minutes} minutes"
  if minutes > 120
    hours = Math.ceil(minutes/60)
    time = "#{hours} hours"
  return "#{data.user} has *#{env}* booked for the next #{time}."

cancelBooking = (data) ->
  data.expires = new Date(0)
  if data.timeoutId
    clearTimeout(data.timeoutId)

# This fixes an issue with some robot brains changing date objects to strings when persisting
fixExpires = (data) ->
  data.expires = new Date(data.expires) if typeof data.expires is 'string'

module.exports = (robot) ->
  robot.brain.on 'loaded', =>
    robot.brain.data.bookstage ||= {}

  robot.respond /bookstage book\s?([A-Za-z]+)*\s?(\d+)*/i, (res) ->
    message = new Message(res.match[1], res.match[2])
    env = message.getEnv()
    hours = message.gethours()

    bookEnv(env, robot.brain.data.bookstage[env], res, hours)
    res.send status(env, robot.brain.data.bookstage[env])

  robot.respond /bookstage who\s?([A-Za-z]+)*/i, (res) ->
    message = new Message(res.match[1])
    env = message.getEnv()

    res.send status(env, robot.brain.data.bookstage[env])

  robot.respond /bookstage cancel\s?([A-Za-z]+)*/i, (res) ->
    message = new Message(res.match[1])
    env = message.getEnv()

    cancelBooking(robot.brain.data.bookstage[env])
    res.send status(env, robot.brain.data.bookstage[env])

  robot.respond /bookstage add\s?([A-Za-z]+)*/i, (res) ->
    message = new Message(res.match[1])
    env = message.getEnv()

    robot.brain.data.bookstage[env] ||= { user: "initial", expires: new Date(0) }
    res.send status(env, robot.brain.data.bookstage[env])

  robot.respond /bookstage remove\s?([A-Za-z]+)*/i, (res) ->
    message = new Message(res.match[1])
    env = message.getEnv()

    cancelBooking(robot.brain.data.bookstage[env])
    delete robot.brain.data.bookstage[env]
    res.send "Deleted *#{env}*"

  robot.respond /bookstage list/i, (res) ->
    statusText = ""
    keys = Object.keys(robot.brain.data.bookstage).sort()
    for env in keys
      statusText += "#{status(env, robot.brain.data.bookstage[env])}\n"
    res.send statusText
