moment = require 'moment'
{Album, Image, User, Vote} = require '../models'
constants = require '../common/constants'
ranking = require '../ranking'
{redirect_to_image} = require './image_controller'
{redirect_to_album} = require './album_controller'



# This method is used by the next / previous buttons when viewing images or albums
redirect_to_content = (req, res, iterator_function) ->
  error = (err) ->
    req.flash 'error', {msg: "Could not find image or album."}
    res.redirect '/'

  goToContent = (reply, originalUrl) ->
    if !reply
      return res.redirect originalUrl

    if typeof reply == 'array'
      reply = reply[0]
    if reply.indexOf(constants.album_prefix) == 0
      return redirect_to_album reply, req, res
    else
      return redirect_to_image reply, req, res

  if req.param('imageId')?
    Image.find({where: {image_id: req.param('imageId')}}).success (image) ->
      # Now we have the image
      iterator_function image.id, (reply) ->
        goToContent reply, '/image/' + req.param('imageId')
    .catch error
  else if req.param('albumId')?
    Album.find(req.param('albumId')).then (album) ->
      # Now we have the album
      iterator_function constants.album_prefix + album.id, (reply) ->
        goToContent reply, '/album/' + req.param('albumId')
    .catch error
  else
    # Neither id specified
    error()

get_next = (req, res) ->
  redirect_to_content req, res, ranking.get_next_rank

get_previous = (req, res) ->
  redirect_to_content req, res, ranking.get_previous_rank


_vote_helper = (req, res, score_increment, isImage) ->
  fail = (err) ->
    console.log err
    res.send {msg: 'error'}

  getNewScore = (votes, update_in_redis) ->
    mysql_new_val = score_increment

    # We are un-voting
    if votes[0].value == score_increment
      mysql_new_val = 0
      score_increment = -score_increment
    else if Math.abs(score_increment - votes[0].value) == 2
      # We are completely switching out vote, double the score change
      score_increment *= 2

    votes[0].updateAttributes({value: mysql_new_val}).then () ->
      update_in_redis score_increment
    .catch fail

  if isImage
    imageId = req.param 'imageId'
    votingImage = null
    Image.find({where: {image_id: imageId}}).then (image) ->
      if not image.score_base?
        throw new Error("Cannot vote on this image.")
      votingImage = image
      return req.user.getVotes({where: 'ImageId=' + image.id})
    .then (votes) ->
      update_image_in_redis = (new_score_change) ->
        ranking.vote_image new_score_change, req, votingImage.id, (err, reply) ->
          score = ranking.get_pretty_score reply, votingImage.score_base
          res.send {
            id: votingImage.image_id
            score
          }
      if not votes.length
        new_vote = Vote.build {
          value: score_increment
          UserId: req.user.id
          ImageId: votingImage.id
        }
        new_vote.save().then () ->
          update_image_in_redis score_increment
        .catch fail
      else
        getNewScore votes, update_image_in_redis
    .catch fail
  else
    # Updating vote for an album
    albumId = req.param 'albumId'
    votingAlbum = null
    Album.find(albumId).then (album) ->
      votingAlbum = album
      return req.user.getVotes({where: 'AlbumId=' + album.id})
    .then (votes) ->
      update_album_in_redis = (new_score_change) ->
        ranking.vote_album new_score_change, req, albumId, (err, reply) ->
          score = ranking.get_pretty_score reply, votingAlbum.scoreBase
          res.send {
            id: albumId
            score
          }
      if not votes.length
        newVote = Vote.build {
          value: score_increment
          UserId: req.user.id
          AlbumId: albumId
        }
        newVote.save().then () ->
          update_album_in_redis score_increment
        .catch fail
      else
        getNewScore votes, update_album_in_redis
    .catch fail

get_upvote = (req, res) ->
  isImage = req.param('imageId')?
  return _vote_helper req, res, 1, isImage

get_downvote = (req, res) ->
  isImage = req.param('imageId')?
  return _vote_helper req, res, -1, isImage

get_user_uploaded = (req, res) ->
  my_user_id = req.user and req.user.id
  user_id = req.params.user_id

  User.find(
    where: {
      id: user_id
    },
    include: [Album, Image]
  ).success (user) ->
    if not user
      req.flash 'errors', {msg: 'User not found.'}
      return res.redirect '/'

    displayContent = []
    currentRow = []

    # TODO sort the images and albums together by timestamp
    # The returned images include all the albums, we want to collect these but maintain the ordering
    albumIdToAlbum = {}
    for album in user.Albums
      albumIdToAlbum[album.id] = album

    albumToIndex = {}
    allImages = (image for image in user.Images.reverse())
    allContent = []
    for image, index in allImages
      if not image.AlbumId?
        allContent.push {isImage: true, image, prettyDate: moment(image.createdAt).calendar()}
      else
        # this image is in an album, see if it's in the albumToIndexMap
        if image.AlbumId of albumToIndex
          i = albumToIndex[image.AlbumId]
          allContent[i].album.images.unshift image
        else
          album = albumIdToAlbum[image.AlbumId]
          allContent.push {isImage: false, album, prettyDate: moment(album.createdAt).calendar()}
          # The index of this album is the length - 1
          i = allContent.length - 1
          albumToIndex[album.id] = i
          allContent[i].album.images = [image]

    for content, index in allContent
      if index % 4 == 0 and currentRow.length
        displayContent.push currentRow
        currentRow = []
      currentRow.push content

    if currentRow.length
      displayContent.push currentRow

    if my_user_id == parseInt(user_id)
      title = 'My Uploads'
      your_or_their = "Your Uploads"
      should_allow_delete = true
    else
      title = user.username
      your_or_their = "Uploads by " + user.username
      should_allow_delete = false

    if user.is_mod
      if my_user_id == parseInt(user_id)
        moderator_status = "You are a moderator"
      else
        moderator_status = user.username + " is a moderator"

    should_allow_delete |= (req.user and req.user.is_mod)

    res.render 'uploaded', {
      title
      user: req.user
      content: displayContent
      your_or_their
      moderator_status
      should_allow_delete
    }

module.exports = {
  get_next
  get_previous
  get_upvote
  get_downvote
  get_user_uploaded
}
