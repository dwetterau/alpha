ranking = require '../ranking'
constants = require '../common/constants'
{Album, Image} = require '../models'

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
  # TODO: Redirect to the album page
  newAlbumId = parseInt(reply.substring(constants.album_prefix.length), 10)

module.exports = {
  get_create_album
  post_create_album

  redirect_to_album
}