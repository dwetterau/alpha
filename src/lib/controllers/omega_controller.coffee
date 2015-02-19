passport = require 'passport'

get_login_with_omega = (req, res, next) ->
  passport.authenticate('omega')(req, res, next)

get_login_with_omega_callback = (req, res) ->
  passport.authenticate('omega', failureRedirect: '/user/login')(req, res, () ->
    # Successfully logged in
    req.flash 'success', {msg: "Login successful!"}
    res.redirect '/'
  )

module.exports = {get_login_with_omega, get_login_with_omega_callback}
