{Album, Comment, Image, User} = require '../models'

render_and_return_comments = (comment_list, req, res, content, isImage) ->
  redirect_url = encodeURIComponent("/image/" + image.image_id)
  if comment_list.length == 0
    return res.render 'partials/comments', {user: req.user, image, redirect_url}
  comments = []
  for comment in comment_list
    comment_object = {
      value: comment.value
      user_id: comment.UserId
    }
    # Add the option to delete the comment
    options = []
    if req.user and (req.user.is_mod or comment.UserId == req.user.id)
      options.push {
        link: '/comment/' + comment.id + '/delete'
        text: 'Delete'
      }
    if options.length
      comment_object.options = options
    comments.push comment_object

  user_ids = (comment.user_id for comment in comments)
  User.findAll({where: {id: user_ids}}).success (users) ->
    user_map = {}
    for user in users
      user_map[user.id] = user.username
    for comment in comments
      comment.username = user_map[comment.user_id]
    res.render 'partials/comments', {user: req.user, comments, image, redirect_url}
  .failure () ->
    res.render 'partials/comments', {user: req.user, image, redirect_url}

exports.get_comments_for_image = (req, res) ->
  image_id = req.params.image_id
  Image.find({
    where: {image_id},
    include: [Comment]
  }).success (image) ->
    render_and_return_comments image.Comments, req, res, image, true
  .failure () ->
    res.send {msg: "Couldn't find image."}

exports.get_comments_for_album = (req, res) ->
  albumId = req.params.album_id
  Album.find({where: {id: albumId}, include: [Comment]}).then (album)->
    render_and_return_comments album.Comments, req, res, album, false
  .catch ->
    res.send {msg: "Couldn't find album."}

exports.get_child_comments = (req, res) ->
  # TODO: Get all comments that are a child of the given comment

exports.post_comment = (req, res) ->
  req.assert('comment', 'Comments must be at least a character long.').notEmpty()
  req.assert('image_id', 'Image id must be valid').notEmpty()
  errors = req.validationErrors()
  if errors
    req.flash 'errors', errors
    return res.redirect '/user/create'

  error = () ->
    req.flash 'errors', {msg: 'Failed to post comment.'}
    res.redirect '/image/' + image_id

  image_id = req.body.image_id
  Image.find({
    where: {image_id}
  }).success (image) ->
    # Yay we have the image to set the new comment as.
    new_comment = Comment.build(
      value: req.body.comment
      ImageId: image.id
      UserId: req.user.id
    )
    new_comment.save().success () ->
      req.flash 'success', {msg: 'Comment posted!'}
      res.redirect '/image/' + image_id
  .failure error

exports.get_delete = (req, res) ->
  fail = () ->
    req.flash 'errors', {msg: 'Failed to delete comment.'}
    res.redirect '/'

  Comment.find({
    where: {id: req.params.comment_id}
    include: [Image, Album]
  }).success (comment) ->
    if not (req.user and req.user.is_mod) and comment.UserId != req.user.id
      return fail()
    comment.destroy().success () ->
      req.flash 'success', {msg: 'Deleted comment.'}
      if comment.Image?
        return res.redirect '/image/' + comment.Image.image_id
      else
        return res.redirect '/album/' + comment.Album.id
    .failure fail
  .failure fail
