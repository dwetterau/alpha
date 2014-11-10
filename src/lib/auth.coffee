passport = require 'passport'
LocalStrategy = require 'passport-local'

models = require './models'

passport.serializeUser (user, done) ->
  done null, user.id

passport.deserializeUser (id, done) ->
  models.User.find(id).success (user) ->
    done null, user
  .failure (err) ->
    done err

passport.use new LocalStrategy {usernameField: 'username'}, (username, password, done) ->
  models.User.find({where: {username}}).success (user) ->
    if not user
      return done null, false, {message: 'Invalid username or password.'}
    user.compare_password password, (err, is_match) ->
      if is_match
        return done null, user
      else
        return done null, false, {message: 'Invalid username or password.'}

exports.isAuthenticated = (req, res, next) ->
  if req.isAuthenticated()
    return next()
  res.redirect '/user/login?r=' + encodeURIComponent(req.url)
