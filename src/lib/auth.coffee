passport = require 'passport'
LocalStrategy = require 'passport-local'
OmegaStrategy = require 'passport-omega'
{config, constants} = require('./common')

{User} = require './models'

passport.serializeUser (user, done) ->
  done null, user.id

passport.deserializeUser (id, done) ->
  User.find(id).success (user) ->
    done null, user
  .failure (err) ->
    done err

passport.use new LocalStrategy {usernameField: 'username'}, (username, password, done) ->
  User.find({where: {username}}).success (user) ->
    if not user
      return done null, false, {message: 'Invalid username or password.'}
    user.compare_password password, (err, is_match) ->
      if is_match
        return done null, user
      else
        return done null, false, {message: 'Invalid username or password.'}

passport.use new OmegaStrategy config.get("omega_config"), (accessToken, _, profile, done) ->

  User.find({where: {thirdPartyId: constants.omega_type_prefix + profile.id}}).then (user) ->
    if user
      done null, user
    else
      # User does not exist yet, create it
      newUser = User.build {
        username: profile.username
        thirdPartyId: constants.omega_type_prefix + profile.id
      }
      newUser.save().then () ->
        done null, newUser
      .catch (err) ->
        # Probably a username collision
        if profile.emails? and profile.emails.length
          newUser.username = profile.emails[0].value
        else
          newUser.username = profile.username + ("" + Math.floor(Math.random() * 1000))

        newUser.save().then () ->
          done null, newUser
        .catch (err) ->
          done err
  .catch (err) ->
    done err

exports.isAuthenticated = (req, res, next) ->
  if req.isAuthenticated()
    return next()
  res.redirect '/user/login?r=' + encodeURIComponent(req.url)
