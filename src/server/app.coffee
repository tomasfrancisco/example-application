# required modules
_              = require "underscore"
async          = require "async"
http           = require "http"
express        = require "express"
path           = require "path"
methodOverride = require "method-override"
bodyParser     = require "body-parser"
socketio       = require "socket.io"
errorHandler   = require "error-handler"
net			       = require "net"
stream         = require "stream"
socketstream   = require "socket.io-stream"

log       = require "./lib/log"
db        = require "./lib/db"
Generator = require "./lib/Generator"
personGeneratorService = require "./lib/personGeneratorService"

app       = express()
server    = http.createServer app
io        = socketio.listen server

netServer = null

# collection of client sockets
sockets = []




db.setup()

# websocket connection logic
io.on "connection", (socket) ->
  socketCursor = null

	# add socket to client sockets
  sockets.push socket
  if netServer isnt null and sockets.length is 1
    netServer.resume()
    log.info "[RESUMED] person-generator stream"
  log.info "Socket connected, #{sockets.length} client(s) active"

  feed = (filter, socket) =>
    @socketCursor = null
    db.personChanges filter, (err, cursor) =>
      throw err if err
      @socketCursor = cursor if @socketCursor is null

      cursor.each (err, row) ->
        log.error "Reading change:", err if err
        socket.emit "persons:create", row.new_val

  feed(db.personsFilter(), socket)

  socket.on "persons:filter", (data) =>
    # jsonData = JSON.parse(data)
    @socketCursor.close().then () ->
      feed(db.personsFilter(data.ageMin, data.ageMax, data.gender), socket)

  # disconnect logic
  socket.on "disconnect", ->
    # remove socket from client sockets
    sockets.splice sockets.indexOf(socket), 1
    log.info "Socket disconnected, #{sockets.length} client(s) active"
    if netServer isnt null and sockets.length is 0
      netServer.pause()
      log.info "[PAUSED] person-generator stream"

connect = ->
  personGeneratorService (address) ->
    netServer = new net.Socket()

    netServer.connect address.port, address.address, () ->
      log.info 'Connected to person generator service on ' + address.address + ':' + address.port

    netServer.on 'data', (data) ->
      if netServer isnt null and sockets.length is 0
        netServer.pause()
        log.info "[PAUSED] person-generator stream"
      jsonData = JSON.parse(data)
      db.savePerson jsonData, (err, saved) ->
        if err
          log.error "Error persisting data on RethingDB"

    netServer.on 'error', (err) ->
      log.info 'Error:', err
      log.warn 'Trying to connect to generator service in 3 sec...'
      setTimeout connect, 3000

    netServer.on 'end', () =>
      log.info 'Connection to generator closed.'
      log.warn 'Trying to connect to generator service in 3 sec...'
      setTimeout connect, 3000

connect()

# express application middleware
app
	.use bodyParser.urlencoded extended: true
	.use bodyParser.json()
	.use methodOverride()
	.use express.static path.resolve __dirname, "../client"

# express application settings
app
	.set "view engine", "jade"
	.set "views", path.resolve __dirname, "./views"
	.set "trust proxy", true

# express application routess
app
	.get "/", (req, res, next) =>
		res.render "main"

# start the server
server.listen 3000
log.info "Listening on 3000"
