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
    res.redirect '/album/create'

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
    req.flash "Album created!"
    res.redirect '/'
  .catch errorExit

module.exports = {get_create_album, post_create_album}