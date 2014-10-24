models = require '../models'

get_index = (req, res) ->
  # TODO: Don't display all users on the index page...
  models.User.findAll
    include: [ models.Image ]
  .success (users) ->
    res.render 'index',
      users: users

get_in = (req, res) ->
  res.render 'logged_in',
    user_id: req.user.id
    username: req.user.username

module.exports = {
  get_index
  get_in
}