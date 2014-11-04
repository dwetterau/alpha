redis = require 'redis'
client = redis.createClient()

constants = require './common/constants'

# Note that this score is calculated in reverse so that the sort is in descending order

exports.add_new_image = (req, image_id, callback) ->
  creation_time = new Date().getTime()
  time_component = (constants.ranking_start_time - creation_time) / (12 * 60 * 60 * 1000)
  client.zadd constants.image_ranking_key, time_component, image_id, (err, reply) ->
    callback(err, constants.ranking_start_time - creation_time)

exports.vote_image = (score, req, image_id, callback) ->
  # Note that the negative sign in front of score allows the logical thing to be passed in
  client.zincrby constants.image_ranking_key, -score, image_id, callback

exports.get_best = (count, offset, callback) ->
  client.zrange constants.image_ranking_key, offset, offset + count - 1, 'WITHSCORES', callback

exports.get_next_rank = (id, callback) ->
  client.zrank constants.image_ranking_key, id, (err, current_rank) ->
    t_rank = current_rank + 1
    client.zrange constants.image_ranking_key, t_rank, t_rank, (err, new_rank) ->
      if not new_rank.length
        return callback null
      return callback new_rank

exports.get_previous_rank = (id, callback) ->
  client.zrank constants.image_ranking_key, id, (err, current_rank) ->
    if current_rank == 0
      return callback null
    t_rank = current_rank - 1
    client.zrange constants.image_ranking_key, t_rank, t_rank, (err, new_rank) ->
      return callback new_rank[0]

exports.get_score = (id, callback) ->
  client.zscore constants.image_ranking_key, id, callback

exports.get_pretty_score = (raw_value, score_base) ->
  return -Math.round(raw_value - (score_base / (12 * 60 * 60 * 1000)))

exports.remove_image = (id, callback) ->
  client.zrem constants.image_ranking_key, id, callback
