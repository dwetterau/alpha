ranking = require '../ranking'
constants = require '../common/constants'
{Album, Image, User} = require '../models'

get_create_album = (req, res) ->
  res.render 'album_upload',
    user: req.user
    title: 'Create Album'

post_create_album = (req, res) ->
  title = req.param 'title' || ''
  description = req.param 'description' || ''
  images = req.param 'images'

  errorExit = (errors) ->
    req.flash 'errors', errors
    res.send redirect: '/album/create'

  if not images.length
    return errorExit {msg: "No images in album."}

  newAlbum = Album.build {
    title
    description
    UserId: req.user.id
  }
  newAlbum.save().then () ->
    imageIds = (image.id for image in images)
    return Image.update {AlbumId: newAlbum.id}, {where: {id: imageIds}}
  .then () ->
    ranking.add_new_album req, newAlbum.id, (err, reply) ->
      if err
        return errorExit err
      newAlbum.scoreBase = reply
      newAlbum.save().then () ->
        req.flash "Album created!"
        res.send redirect: '/'
      .catch errorExit
  .catch errorExit

redirect_to_album = (reply, req, res) ->
  error = (err) ->
    req.flash 'error', {msg: "Could not find album."}
    res.redirect '/'

  if not reply
    # There must not be a next or previous album
    return res.redirect '/'

  nextAlbumId = parseInt(reply.substring(constants.album_prefix.length), 10)
  Album.find(nextAlbumId).success (nextAlbum) ->
    res.redirect '/album/' + nextAlbum.id
  .failure (err)  ->
    return error err

get_album = (req, res) ->
  Album.find({
    where: {id: req.params.album_id}
    include: [User, Image]
  }).then (album) ->
    ranking.get_album_score album.id, (err, reply) ->
      if err
        req.flash 'error', {msg: "Couldn't get score of album"}
        score = '?'
      else
        score = ranking.get_pretty_score reply, album.scoreBase

      render_dict = {
        album
        score
        title: 'Album'
        user: req.user
        images: album.Images
        uploader: album.User
        vote: 0
      }
      if req.user
        req.user.getVotes({where: 'AlbumId=' + album.id}).success (votes) ->
          if votes.length
            render_dict.vote = votes[0].value
          res.render 'album', render_dict
        .failure () ->
          req.flash 'error', {msg: "Could not retrieve your votes for the album."}
          res.redirect '/album/' + album.id
      else
        res.render 'album', render_dict

  .catch (err) ->
    req.flash 'error', {msg: "Could not find album."}
    res.redirect '/'

get_delete = (req, res) ->
  fail = (err) ->
    req.flash 'errors', {msg: 'Failed to delete album.'}
    return res.redirect '/'

  imageIds = []
  Album.find({
    where: {id: req.params.album_id},
    include: [User, Image]
  }).then (album) ->
    if not req.user or (req.user.is_mod or album.User.id != req.user.id)
      return fail("User not authorized")

    imageIds = (image.id for image in album.Images)
    ranking.remove_album album.id, (err, reply) ->
      if err
        return fail()
      album.destroy().then ->
        return Image.destroy {where: {id: imageIds}}
      .then ->
        req.flash 'success', msg: "Deleted album."
        return res.redirect '/user/' + album.User.id + '/uploaded'
      .catch fail
  .catch fail

module.exports = {
  get_create_album
  post_create_album
  get_album
  get_delete

  redirect_to_album
}