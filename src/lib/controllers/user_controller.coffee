passport = require 'passport'
moment = require 'moment'

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
  redirect = req.param('r')
  res.render 'login', {
    title: 'Login'
    redirect
  }

post_user_login = (req, res, next) ->
  req.assert('username', 'Username is not valid.').notEmpty()
  req.assert('password', 'Password cannot be blank.').notEmpty()
  redirect = req.param('redirect')
  redirect_string = if redirect then '?r=' + encodeURIComponent(redirect) else ''
  redirect_url = decodeURIComponent(redirect)

  errors = req.validationErrors()
  if errors?
    req.flash 'errors', errors
    return res.redirect '/user/login' + redirect_string

  passport.authenticate('local', (err, user, info) ->
    if err?
      return next(err)
    if not user
      req.flash 'errors', {msg: info.message}
      return res.redirect '/user/login' + redirect_string
    req.logIn user, (err) ->
      if err?
        return next err

      req.flash 'success', {msg: "Login successful!"}
      res.redirect redirect_url || '/'
  )(req, res, next)

get_user_logout = (req, res) ->
  req.logout()
  res.redirect '/'

post_change_password = (req, res) ->
  req.assert('old_password', 'Password must be at least 4 characters long.').len(4)
  req.assert('new_password', 'Password must be at least 4 characters long.').len(4)
  req.assert('confirm_password', 'Passwords do not match.').equals(req.body.new_password)
  errors = req.validationErrors()

  if errors
    req.flash 'errors', errors
    return res.redirect '/user/password'

  old_password = req.body.old_password
  new_password = req.body.new_password

  fail = () ->
    req.flash 'errors', {msg: 'Failed to update password.'}
    return res.redirect '/user/password'

  models.User.find(req.user.id).success (user) ->
    user.compare_password old_password, (err, is_match) ->
      if not is_match or err
        req.flash 'errors', {msg: 'Current password incorrect.'}
        return fail();

      user.hash_and_set_password new_password, (err) ->
        if err?
          return fail()
        user.save().success () ->
          req.flash 'success', {msg: 'Password changed!'}
          res.redirect '/user/password'
        .failure fail
  .failure fail

get_change_password = (req, res) ->
  res.render 'change_password', {
    user: req.user,
    title: 'Change Password'
  }

get_user_uploaded = (req, res) ->
  my_user_id = req.user and req.user.id
  user_id = req.params.user_id

  models.User.find(
    where: {
      id: user_id
    },
    include: [models.Image]
  ).success (user) ->
    if not user
      req.flash 'errors', {msg: 'User not found.'}
      return res.redirect '/'

    images = []
    current_row = []
    dates = {}
    for image, index in user.Images.reverse()
      if index % 4 == 0 and current_row.length
        images.push current_row
        current_row = []
      current_row.push image
      dates[image.image_id] = moment(image.createdAt).calendar()

    if current_row.length
      images.push current_row

    if my_user_id == parseInt(user_id)
      title = 'My Images'
      your_or_their = "Your Images"
      should_allow_delete = true
    else
      title = user.username
      your_or_their = "Images by " + user.username
      should_allow_delete = false

    if user.is_mod
      if my_user_id == parseInt(user_id)
        moderator_status = "You are a moderator"
      else
        moderator_status = user.username + " is a moderator"

    should_allow_delete |= (req.user and req.user.is_mod)

    console.log "moderator_Status", moderator_status
    res.render 'uploaded', {
      title
      user: req.user
      images
      your_or_their
      moderator_status
      should_allow_delete
      dates
    }

module.exports = {
  get_user_create
  post_user_create
  get_user_login
  post_user_login
  get_user_logout
  get_user_uploaded
  get_change_password
  post_change_password
}