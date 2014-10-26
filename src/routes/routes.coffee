express = require 'express'
router = express.Router()
passport_config  = require('../lib/auth')

index_controller = require '../lib/controllers/index_controller'
user_controller = require '../lib/controllers/user_controller'
image_controller = require '../lib/controllers/image_controller'

# GET home page
router.get '/', index_controller.get_index

# POST Create a User
router.post '/user/create', user_controller.post_user_create
router.post '/user/login', user_controller.post_user_login
router.get '/user/logout', user_controller.get_user_logout

# POST
router.get '/image/upload', passport_config.isAuthenticated, image_controller.get_upload
router.post '/image/upload', passport_config.isAuthenticated, image_controller.post_upload

module.exports = router
