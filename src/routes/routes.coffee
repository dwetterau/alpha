express = require 'express'
router = express.Router()
passport_config  = require('../lib/auth')

index_controller = require '../lib/controllers/index_controller'
user_controller = require '../lib/controllers/user_controller'

# GET home page
router.get '/', index_controller.get_index
router.get '/in', passport_config.isAuthenticated, index_controller.get_in

# POST Create a user
router.post '/user/create', user_controller.post_user_create
router.post '/user/login', user_controller.post_user_login
router.get '/user/logout', user_controller.get_user_logout

module.exports = router
