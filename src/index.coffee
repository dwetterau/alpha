bodyParser = require 'body-parser'
busboy = require 'connect-busboy'
cookieParser = require 'cookie-parser'
express = require 'express'
favicon = require 'serve-favicon'
flash = require 'express-flash'
logger = require 'morgan'
methodOverride = require 'method-override'
path = require 'path'
validator = require 'express-validator'

session = require 'express-session'
RedisStore = require('connect-redis')(session)

passport_config = require './lib/auth'
passport = require 'passport'

{ config } = require './lib/common'

all_routes = require './routes/routes'


app = express()

# view engine setup
app.set 'views', path.join(__dirname, 'views')
app.set 'view engine', 'jade'

app.use favicon(__dirname + '/public/favicon.ico')
app.use logger('dev')
app.use busboy()
app.use bodyParser.json()
app.use bodyParser.urlencoded {extended: true}
app.use validator()
app.use methodOverride()
app.use cookieParser()

app.use express.static(path.join(__dirname, '/public'))

# Setup sessions
app.use session
  resave: true
  saveUninitialized: true
  store: new RedisStore()
  secret: config.get('session_secret')
app.use flash()
app.use passport.initialize()
app.use passport.session()

# Setup all the routes
app.use '/', all_routes

# catch 404 and forward to error handler
app.use (req, res, next) ->
  err = new Error('Not Found')
  err.status = 404
  next(err)

if app.get('env') == 'local'
  # development error handler
  # will print stacktrace in local mode
  app.use (err, req, res, next) ->
    res.status(err.status || 500)
    errorObj =
      message: err.message
      error: err
    res.render('error', errorObj)
else
  # production error handler
  # no stacktraces leaked to user
  app.use (err, req, res, next) ->
    res.status(err.status || 500)
    errorObj =
      message: err.message
      error: {}
    res.render('error', errorObj)

app.listen(config.get('PORT'))

module.exports = app
