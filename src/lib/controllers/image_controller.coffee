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

  # Gif routes:
  coalesced_path = './image/original/' + id + '-coalesced.gif'
  optimized_path_gif = './image/optimized/' + id + '.gif'
  thumbnail_path_gif = './image/thumbnail/' + id + '.gif'

  allowed_types = {'JPG', 'JPEG', 'PNG', 'GIF'}

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
      # We call this when the image files are ready to be served
      build_db_object = (extension) ->
        if not description or not title
          return error_exit {msg: "Didn't receive description or title."}
        # Resizing and saving done, now make the image object
        new_image = models.Image.build {
          title
          description
          image_id: id
          UserId: req.user.id
          extension
        }
        new_image.save().success () ->
          ranking.add_new_image req, new_image.id, (err, reply) ->
            if err
              return error_exit err
            new_image.score_base = reply
            new_image.save().success () ->
              req.flash 'success', {msg: 'Upload Successful!'}
              res.redirect '/image/' + id
            .failure (err) ->
              return error_exit err
        .failure (err) ->
          return error_exit err

      # Now we need to convert the image to jpg and resize for thumbnails
      im.identify original_path, (err, features) ->
        if err or features.format not of allowed_types
          if err
            console.log "Image conversion error", err
          return error_exit {
            msg: 'Only \'png\', \'jpg\', or \'gif\' images may be uploaded at this time.'
          }

        if features.format == 'GIF'
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

_vote_helper = (req, res, score_increment) ->
  fail = (err) ->
    console.log err
    res.send {msg: 'error'}
  models.Image.find({
    where:
      image_id: req.params.image_id
  }).success (image) ->
    req.user.getVotes({where: 'ImageId=' + image.id}).success (votes) ->
      update_in_redis = (new_score_change) ->
        ranking.vote_image new_score_change, req, image.id, (err, reply) ->
          score = ranking.get_pretty_score reply, image.score_base
          res.send {
            id: image.image_id
            score
          }
      if not votes.length
        new_vote = models.Vote.build {
          value: score_increment
          UserId: req.user.id
          ImageId: image.id
        }
        new_vote.save().success () ->
          update_in_redis score_increment
        .failure fail
      else
        mysql_new_val = score_increment

        # We are un-voting
        if votes[0].value == score_increment
          mysql_new_val = 0
          score_increment = -score_increment
        else if Math.abs(score_increment - votes[0].value) == 2
          # We are completely switching out vote, double the score change
          score_increment *= 2

        votes[0].updateAttributes({value: mysql_new_val}).success () ->
          update_in_redis score_increment
        .failure fail
    .failure fail

get_upvote = (req, res) ->
  return _vote_helper req, res, 1

get_downvote = (req, res) ->
  return _vote_helper req, res, -1

get_image = (req, res) ->
  models.Image.find({
    where: {image_id: req.params.image_id}
    include: [models.User]
  }).success (image) ->
    ranking.get_score image.id, (err, reply) ->
      if err
        req.flash 'error', {msg: "Couldn't get score of image"}
        score = '?'
      else
        score = ranking.get_pretty_score reply, image.score_base

      render_dict = {
        image
        score
        title: 'Image'
        user: req.user
        uploader: image.User
        vote: 0
      }
      if req.user
        req.user.getVotes({where: 'ImageId=' + image.id}).success (votes) ->
          if votes.length
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
  get_upvote
  get_downvote
  get_image
  get_next
  get_previous
  get_delete
}
