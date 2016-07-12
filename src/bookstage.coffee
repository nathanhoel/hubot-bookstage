# Description:
#   Bookstage manages who is currently using your team's staging server.
#   Hubot also notifies you 30 minutes before the end of a reservation.
#
# Dependencies:
#   pad
#
# Configuration:
#   HUBOT_BOOKSTAGE_MONOSPACE_WRAPPER - characters to wrap status in (placed before and after) to make it monospaced
#
# Commands:
#   hubot bookstage add <env> [category] - Add a new server. 'bs' is an alias for 'bookstage'.
#   hubot bookstage book <env> [<hours> <reason>] - Book a server. Default is 1 hour.
#   hubot bookstage cancel <env> - Cancel a booking.
#   hubot bookstage list - List status of all staging servers.
#   hubot bookstage who <env> - Show status of a single server.
#
# Author:
#   tinifni, nathanhoel

pad = require('pad')

MS_HALF_HOUR = 1800000
MONOSPACE_WRAPPER = if process.env.HUBOT_BOOKSTAGE_MONOSPACE_WRAPPER then process.env.HUBOT_BOOKSTAGE_MONOSPACE_WRAPPER else ''

class Message
  constructor: (res) ->
    @env = res.match[2]
    @hours = @category = res.match[3]
    @reason = res.match[4]
  getEnv: ->
    if @env == undefined
      return 'staging'
    else
      return @env

  getHours: ->
    if @hours == undefined
      return 1
    else
      return Number(@hours)

  getReason: ->
    if @reason == undefined
      return ''
    else
      return @reason

  getCategory: ->
    if @category == undefined
      return ''
    else
      return @category

bookEnv = (message, data, res) ->
  ms = message.getHours() * 1000 * 60 * 60
  if data.user != res.message.user.name && Date.now() < data.expires
    return false

  data.user = res.message.user.name
  data.expires = Date.now() + ms
  data.reason = message.getReason()
  setTimeout () ->
    res.reply "You have 30 minutes remaining on your reservation of *#{message.getEnv()}*"
  , (ms - MS_HALF_HOUR)

status = (env, data) ->
  return monospaceWrap("#{statusHeaders()}\n#{statusRow(env, data)}")

statusRow = (env, data) ->
  return joinSections([env, data.category, '-', '-', '']) if data.expires <= Date.now()

  minutes = Math.ceil((data.expires - Date.now())/(60*1000))
  time = "#{minutes} minutes"
  if minutes > 120
    hours = Math.ceil(minutes/60)
    time = "#{hours} hours"
  return joinSections([env, data.category, data.user, time, data.reason])

statusHeaders = () ->
  return joinSections(['*Name*', '*Category*', '*Booked By*', '*Remaining*', '*Reason*'])

joinSections = (sections) ->
  padding = if MONOSPACE_WRAPPER.length > 0 then 15 else 0
  for section, i in sections
    sections[i] = '' if sections[i] == undefined
    sections[i] = "#{pad(sections[i], padding)}"
  text = sections.join(' | ')
  return text

monospaceWrap = (text) ->
  return "#{MONOSPACE_WRAPPER}#{text}#{MONOSPACE_WRAPPER}"

cancelBooking = (data) ->
  data.expires = 0

module.exports = (robot) ->
  robot.brain.on 'loaded', =>
    robot.brain.data.bookstage ||= {}

  robot.respond /(bookstage|bs) book\s?([0-9A-Za-z-]+)*\s?(\d+)*\s?(.*)/i, (res) ->
    message = new Message(res)
    env = message.getEnv()
    bookEnv(message, robot.brain.data.bookstage[env], res)
    res.send status(env, robot.brain.data.bookstage[env])

  robot.respond /(bookstage|bs) who\s?([0-9A-Za-z-]+)*/i, (res) ->
    message = new Message(res)
    env = message.getEnv()
    res.send status(env, robot.brain.data.bookstage[env])

  robot.respond /(bookstage|bs) cancel\s?([0-9A-Za-z-]+)*/i, (res) ->
    message = new Message(res)
    env = message.getEnv()
    data = robot.brain.data.bookstage[env]
    cancelBooking(data)
    res.send status(env, data)

  robot.respond /(bookstage|bs) add\s?([0-9A-Za-z-]+)*\s?(.*)/i, (res) ->
    message = new Message(res)
    env = message.getEnv()
    robot.brain.data.bookstage[env] ||= { name: env, category: message.getCategory(), user: "initial", expires: Date.now(), reason: "" }
    res.send status(env, robot.brain.data.bookstage[env])

  robot.respond /(bookstage|bs) remove\s?([0-9A-Za-z-]+)*/i, (res) ->
    message = new Message(res)
    env = message.getEnv()
    cancelBooking(robot.brain.data.bookstage[env])
    delete robot.brain.data.bookstage[env]
    res.send "Deleted #{env}"

  robot.respond /(bookstage|bs) list/i, (res) ->
    statusText = "#{statusHeaders()}\n"
    servers = []
    servers.push(val) for key, val of robot.brain.data.bookstage
    servers = servers.sort (a, b) ->
      return -1 if a.category.toLowerCase() < b.category.toLowerCase() || (a.category.toLowerCase() == b.category.toLowerCase() && a.name.toLowerCase() < b.name.toLowerCase())
      return 1 if b.category.toLowerCase() < a.category.toLowerCase() || (b.category.toLowerCase() == a.category.toLowerCase() && b.name.toLowerCase() < a.name.toLowerCase())
      return 0

    for server in servers
      statusText += "#{statusRow(server.name, server)}\n"
    res.send monospaceWrap(statusText)
