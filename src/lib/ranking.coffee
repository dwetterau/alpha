redis = require 'redis'
client = redis.createClient()

constants = require './common/constants'

# Note that this score is calculated in reverse so that the sort is in descending order

exports.add_new_image = (req, image_id, callback) ->
  creation_time = new Date().getTime()
  time_component = (constants.ranking_start_time - creation_time) / (60 * 1000)
  client.zadd constants.image_ranking_key, time_component, image_id, callback

exports.upvote_image = (req, image_id, callback) ->
  # TODO: Check in Redis to make sure this person hasn't voted.
  client.zincrby constants.image_ranking_key, -1, image_id, callback

exports.downvote_image = (req, image_id, callback) ->
  client.zincrby constants.image_ranking_key, 1, image_id, callback

exports.get_best = (count, offset, callback) ->
  client.zrangebyscore(constants.image_ranking_key, '-inf', '+inf', 'WITHSCORES', 'LIMIT',
    offset, count, callback)
