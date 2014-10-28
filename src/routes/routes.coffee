express = require 'express'
router = express.Router()
passport_config  = require('../lib/auth')

index_controller = require '../lib/controllers/index_controller'
user_controller = require '../lib/controllers/user_controller'
image_controller = require '../lib/controllers/image_controller'

# GET home page
router.get '/', index_controller.get_index

# User routes
router.get '/user/create', user_controller.get_user_create
router.post '/user/create', user_controller.post_user_create
router.get '/user/login', user_controller.get_user_login
router.post '/user/login', user_controller.post_user_login
router.get '/user/logout', user_controller.get_user_logout

# Logged in image routes
router.get '/image/upload', passport_config.isAuthenticated, image_controller.get_upload
router.post '/image/upload', passport_config.isAuthenticated, image_controller.post_upload
router.get '/image/uploaded', passport_config.isAuthenticated, image_controller.get_uploaded
router.get '/image/:image_id/up', passport_config.isAuthenticated, image_controller.get_upvote
router.get '/image/:image_id/down', passport_config.isAuthenticated, image_controller.get_downvote

# Public image routes
router.get '/image/:image_id', image_controller.get_image
router.get '/image/:image_id/next', image_controller.get_next
router.get '/image/:image_id/previous', image_controller.get_previous

module.exports = router
