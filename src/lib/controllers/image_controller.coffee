fs = require 'fs-extra'
im = require 'imagemagick'
gm = require 'gm'
uuid = require 'node-uuid'

models = require '../models'
ranking = require '../ranking'

get_upload = (req, res) ->
  res.render 'upload',
    user: req.user
    title: 'Upload'

post_upload_helper = (error_exit, success_exit, doRanking, req) ->
  id = uuid.v4()
  original_path = './image/original/' + id
  optimized_path = './image/optimized/' + id + ".jpg"
  thumbnail_path = './image/thumbnail/' + id + ".jpg"

  # Gif routes:
  coalesced_path = './image/original/' + id + '-coalesced.gif'
  optimized_path_gif = './image/optimized/' + id + '.gif'
  thumbnail_path_gif = './image/thumbnail/' + id + '.gif'

  allowed_types = {'JPG', 'JPEG', 'PNG', 'GIF'}

  description = ''
  title = ''
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
      # We call this when the image files are ready to be served
      build_db_object = (extension) ->
        # Resizing and saving done, now make the image object
        new_image = models.Image.build {
          title
          description
          image_id: id
          UserId: req.user.id
          extension
        }
        new_image.save().success () ->
          startRanking = (callback) ->
            if doRanking
              ranking.add_new_image req, new_image.id, (err, reply) ->
                new_image.score_base = reply
                if err
                  return error_exit err
                else
                  callback()
            else
              callback()

          startRanking () ->
            new_image.save().success () ->
              success_exit new_image
            .failure (err) ->
              return error_exit err
        .failure (err) ->
          return error_exit err

      # Now we need to convert the image to jpg and resize for thumbnails
      gm(original_path).format (err, features) ->
        if err or features not of allowed_types
          if err
            console.log "Image conversion error", err
            return error_exit {
              msg: 'Ah this must be Dan\'s Image'
            }
          return error_exit {
            msg: 'Only \'png\', \'jpg\', or \'gif\' images may be uploaded at this time.'
          }

        if features == 'GIF'
          im.convert [original_path, '-coalesce', coalesced_path], (err) ->
            if err
              return error_exit err

            im.convert [coalesced_path, '-thumbnail', '200x200^', '-gravity', 'center', '-extent',
                        '200x200', '-auto-orient', thumbnail_path_gif], (err) ->
              if err
                return error_exit err
              im.convert [coalesced_path, '-resize', '640\>', '-auto-orient', '-background',
                          'white', optimized_path_gif], (err) ->
                if err
                  return error_exit err
                build_db_object('.gif')
        else
          # Convert the image to a .jpg with the proper resizing
          im.convert [original_path, '-resize', '640\>', '-auto-orient', '-background',
                      'white', '-flatten', optimized_path], (err) ->
            if err
              return error_exit err
            # Now make a thumbnail of it too
            im.convert [original_path, '-thumbnail', '200x200^', '-gravity', 'center', '-extent',
                        '200x200', '-auto-orient', thumbnail_path], (err) ->
              if err
                return error_exit err
              build_db_object('.jpg')

post_upload = (req, res) ->
  error_exit = (err) ->
    console.log "got error:", err
    req.flash 'errors', err
    res.redirect '/image/upload'

  success_exit = (image) ->
    req.flash 'success', {msg: 'Upload Successful!'}
    res.redirect '/image/' + image.id

  post_upload_helper error_exit, success_exit, true, req

post_api_upload = (req, res) ->
  error_exit = (err) ->
    res.send {status: "error", err}

  success_exit = (image) ->
    res.send {status: "ok", image}

  post_upload_helper error_exit, success_exit, false, req

get_image = (req, res) ->
  models.Image.find({
    where: {image_id: req.params.image_id}
    include: [models.User]
  }).success (image) ->
    ranking.get_score image.id, (err, reply) ->
      score = 0
      if err or reply == null
        # this image has no score
        score = null
      else
        score = ranking.get_pretty_score reply, image.score_base

      render_dict = {
        image
        score
        title: 'Image'
        user: req.user
        uploader: image.User
        vote: 0
        votable: score != null
      }
      if req.user
        req.user.getVotes({where: 'ImageId=' + image.id}).success (votes) ->
          if votes.length and score != null
            render_dict.vote = votes[0].value
          res.render 'image', render_dict
        .failure () ->
          req.flash 'error', {msg: "Could not retrieve your votes for the image."}
          res.redirect '/image/' + image.image_id
      else
        res.render 'image', render_dict

  .failure (err) ->
    req.flash 'error', {msg: "Could not find image."}
    res.redirect '/'

redirect_to_image = (rankReply, req, res) ->
  error = (err) ->
    req.flash 'error', {msg: "Could not find image."}
    res.redirect '/'

  nextImageId = parseInt(rankReply, 10)
  if not nextImageId
    # There must not be a next or previous image
    return res.redirect '/'
  models.Image.find(nextImageId).success (next_image) ->
    res.redirect '/image/' + next_image.image_id
  .failure (err)  ->
    return error err

get_delete = (req, res) ->
  fail = () ->
    req.flash 'errors', {msg: 'Failed to delete image.'}
    res.redirect '/'

  models.Image.find({
    where: {image_id: req.params.image_id}
    include: [models.User]
  }).success (image) ->
    if not (req.user and req.user.is_mod) and image.User.id != req.user.id
      return fail()

    ranking.remove_image image.id, (err, reply) ->
      if err
        return fail()
      image.destroy().success () ->
        req.flash 'success', {msg: 'Deleted image.'}
        return res.redirect '/user/' + image.User.id + '/uploaded'
      .failure () ->
        return fail()

module.exports = {
  get_upload
  post_upload
  post_api_upload
  get_image
  get_delete

  redirect_to_image
}
