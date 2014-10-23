express = require 'express'
router = express.Router()
room_manager = require '../serverjs/room_manager'

# GET home page
router.get '/', (req, res) ->
  # This should generate a room_id that other users will use to connect.
  room_id = room_manager.get_room_id()
  res.render 'index'

module.exports = router