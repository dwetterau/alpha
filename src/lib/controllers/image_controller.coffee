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
        im.convert [original_path, '-thumbnail', '200x200^', '-gravity', 'center',
                    '-extent', '200x200', thumbnail_path], (err, stdout, stderr) ->
          if err
            return error_exit err
          if not description or not title
            return error_exit {msg: "Didn't receive description or title."}
          # Resizing and saving done, now make the image object
          new_image = models.Image.build {
            title
            description
            image_id: id
            UserId: req.user.id
          }
          new_image.save().success () ->
            ranking.add_new_image req, new_image.id, (err, reply) ->
              if err
                return error_exit err
              new_image.score_base = reply
              new_image.save().success () ->
                req.flash 'success', {msg: 'Upload Successful!'}
                res.redirect '/image/upload'
              .failure (err) ->
                return error_exit err
          .failure (err) ->
            return error_exit err

get_uploaded = (req, res) ->
  models.User.find({
    id: req.user.user_id
    include: [models.Image]
  }).success (user) ->
    images = []
    current_row = []
    for image, index in user.Images
      if index % 4 == 0 and current_row.length
        images.push current_row
        current_row = []
      current_row.push image

    if current_row.length
      images.push current_row

    res.render 'uploaded', {
      title: 'My Images'
      user,
      images
    }

get_upvote = (req, res) ->
  console.log req.header('Referrer')
  models.Image.find({
    where:
      image_id: req.params.image_id
  }).success (image) ->
    ranking.upvote_image req, image.id, (err, reply) ->
      req.flash 'success', {msg: 'Upvoted!'}
      res.redirect '/'

get_downvote = (req, res) ->
  models.Image.find({
    where:
      image_id: req.params.image_id
  }).success (image) ->
    ranking.downvote_image req, image.id, () ->
      req.flash 'info', {msg: 'Downvoted!'}
      res.redirect '/'

get_image = (req, res) ->
  console.log "hitting the get image endpoint"
  models.Image.find({where: {image_id: req.params.image_id}}).success (image) ->
    ranking.get_score image.id, (err, reply) ->
      if err
        req.flash 'error', {msg: "Couldn't get score of image"}
        res.redirect '/'
      score = ranking.get_pretty_score reply, image.score_base
      res.render 'image', {
        image
        score
        title: 'Image'
        user: req.user
      }
  .failure (err) ->
    req.flash 'error', {msg: "Could not find image."}
    res.redirect '/'

redirect_to_image = (req, res, iterator_function) ->
  error = (err) ->
    console.log "Error getting image:", err
    req.flash 'error', {msg: "Could not find image."}
    res.redirect '/'

  models.Image.find({where: {image_id: req.params.image_id}}).success (image) ->
    # Now we have the image
    iterator_function image.id, (reply) ->
      next_id = parseInt(reply, 10)
      if not next_id
        # There must not be a next or previous image
        return res.redirect '/image/' + req.params.image_id
      models.Image.find(next_id).success (next_image) ->
        res.redirect '/image/' + next_image.image_id
      .failure (err)  ->
        return error err
  .failure (err) ->
    return error err

get_next = (req, res) ->
  redirect_to_image req, res, ranking.get_next_rank

get_previous = (req, res) ->
  redirect_to_image req, res, ranking.get_previous_rank

module.exports = {
  get_upload
  post_upload
  get_uploaded
  get_upvote
  get_downvote
  get_image
  get_next
  get_previous
}
