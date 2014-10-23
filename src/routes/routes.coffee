express = require 'express'
models = require '../lib/models'
router = express.Router()

# GET home page
router.get '/', (req, res) ->
  models.User.findAll
    include: [ models.Image ]
  .success (users) ->
    res.render 'index',
      users: users

router.post '/user/create', (req, res) ->
  username = req.body.username
  password = req.body.password
  models.User.create({username, password}).complete (err, user) ->
    if err?
      res.render 'error', err
    else
      res.redirect '/'

module.exports = router
