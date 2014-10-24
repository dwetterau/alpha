passport = require 'passport'

models = require '../models'

post_user_create = (req, res) ->
  username = req.body.username
  password = req.body.password
  new_user = models.User.build({username})
  new_user.hash_and_set_password password, (err) ->
    if err?
      res.render 'error', err
    else
      new_user.save().success () ->
        res.redirect '/'

post_user_login = (req, res, next) ->
  req.assert('username', 'Username is not valid').notEmpty()
  req.assert('password', 'Password cannot be blank').notEmpty()

  errors = req.validationErrors()
  if errors?
    req.flash 'errors', errors
    return res.redirect '/'

  passport.authenticate('local', (err, user, info) ->
    if err?
      return next(err)
    if not user
      req.flash 'errors', {msg: info.message}
      return res.redirect '/'
    req.logIn user, (err) ->
      if err?
        return next err

      req.flash 'success', {msg: "Login successful!"}
      res.redirect req.session.returnTo || '/in'
  )(req, res, next)

get_user_logout = (req, res) ->
  req.logout()
  res.redirect '/'

module.exports = {
  post_user_create
  post_user_login
  get_user_logout
}