models = require '../models'

get_index = (req, res) ->
  # TODO: Don't display all users on the index page...
  models.User.findAll
    include: [ models.Image ]
  .success (users) ->
    res.render 'index',
      users: users

module.exports = {
  get_index
}