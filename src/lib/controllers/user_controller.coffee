passport = require 'passport'

models = require '../models'

get_user_create = (req, res) ->
  res.render 'create_account',
    title: 'Create Account'

post_user_create = (req, res) ->
  req.assert('username', 'Username must be at least 3 characters long.').len(3)
  req.assert('password', 'Password must be at least 4 characters long.').len(4)
  req.assert('confirm_password', 'Passwords do not match.').equals(req.body.password)
  errors = req.validationErrors()

  if errors
    req.flash 'errors', errors
    return res.redirect '/user/create'

  username = req.body.username
  password = req.body.password
  new_user = models.User.build({username})
  new_user.hash_and_set_password password, (err) ->
    if err?
      res.render 'error', err
    else
      new_user.save().success () ->
        res.redirect '/'

get_user_login = (req, res) ->
  res.render 'login', {
    title: 'Login'
  }

post_user_login = (req, res, next) ->
  req.assert('username', 'Username is not valid.').notEmpty()
  req.assert('password', 'Password cannot be blank.').notEmpty()

  errors = req.validationErrors()
  if errors?
    req.flash 'errors', errors
    return res.redirect '/user/login'

  passport.authenticate('local', (err, user, info) ->
    if err?
      return next(err)
    if not user
      req.flash 'errors', {msg: info.message}
      return res.redirect '/user/login'
    req.logIn user, (err) ->
      if err?
        return next err

      req.flash 'success', {msg: "Login successful!"}
      res.redirect req.session.returnTo || '/'
  )(req, res, next)

get_user_logout = (req, res) ->
  req.logout()
  res.redirect '/'

module.exports = {
  get_user_create
  post_user_create
  get_user_login
  post_user_login
  get_user_logout
}