fs = require 'fs-extra'
im = require 'imagemagick'
uuid = require 'node-uuid'

models = require '../models'
ranking = require '../ranking'

get_upload = (req, res) ->
  res.render 'upload',
    user: req.user
    title: 'Upload'

post_upload = (req, res) ->
  error_exit = (err) ->
    console.log "got error:", err
    req.flash 'errors', err
    res.redirect '/image/upload'

  id = uuid.v4()
  original_path = './image/original/' + id
  optimized_path = './image/optimized/' + id + ".jpg"
  thumbnail_path = './image/thumbnail/' + id + ".jpg"

  description = undefined
  title = undefined
  req.pipe req.busboy
  req.busboy.on 'field', (fieldname, val) ->
    if fieldname == 'description'
      description = val
    else if fieldname == 'title'
      title = val
  req.busboy.on 'file', (fieldname, file, filename) ->
    if not filename
      return error_exit {msg: "No filename."}

    file_stream = fs.createWriteStream original_path
    file.pipe file_stream
    file_stream.on 'close', () ->
      # Now we need to convert the image to jpg and resize for thumbnails
      im.convert [original_path, '-resize', '640', optimized_path], (err, stdout) ->
        if err
          return error_exit err
        # Now make a thumbnail of it too
        im.resize {
          srcPath: optimized_path
          dstPath: thumbnail_path
          width: 200
          height: 200
        }, (err, stdout, stderr) ->
          if err
            return error_exit err
          if not description or not title
            return error_exit {msg: "Didn't receive description or title."}
          # Resizing and saving done, now make the image object
          new_image = models.Image.build {
            title
            description
            image_id: id
          }
          new_image.setUser(req.user)
          new_image.save().success () ->
            ranking.add_new_image req, new_image.id, (err, reply) ->
              if err
                return error_exit err
              req.flash 'success', {msg: 'Upload Successful!'}
              res.redirect '/image/upload'
          .failure (err) ->
            return error_exit err

get_uploaded = (req, res) ->
  models.User.find({
    id: req.user.user_id
    include: [models.Image]
  }).success (user) ->
    res.render 'uploaded', {
      title: 'My Images'
      user
    }

get_upvote = (req, res) ->
  models.Image.find({
    image_id: req.params.image_id
  }).success (image) ->
    ranking.upvote_image req, image.id, () ->
      req.flash 'success', {msg: 'Upvoted!'}
      res.redirect '/'

get_downvote = (req, res) ->
  models.Image.find({
    image_id: req.params.image_id
  }).success (image) ->
    ranking.downvote_image req, image.id, () ->
      req.flash 'info', {msg: 'Downvoted!'}
      res.redirect '/'

module.exports = {
  get_upload
  post_upload
  get_uploaded
  get_upvote
  get_downvote
}
