{Album, Comment, Image, User} = require '../models'

render_and_return_comments = (comment_list, req, res, content, isImage) ->
  if isImage
    redirectUrl = encodeURIComponent("/image/" + content.image_id)
  else
    redirectUrl = encodeURIComponent("/album/" + content.id)

  if comment_list.length == 0
    return res.render 'partials/comments', {user: req.user, content, isImage, redirectUrl}
  comments = []
  for comment in comment_list
    comment_object = {
      value: comment.value
      userId: comment.UserId
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

  user_ids = (comment.userId for comment in comments)
  User.findAll({where: {id: user_ids}}).success (users) ->
    user_map = {}
    for user in users
      user_map[user.id] = user.username
    for comment in comments
      comment.username = user_map[comment.userId]
    res.render 'partials/comments', {user: req.user, content, isImage, comments, redirectUrl}
  .failure () ->
    res.render 'partials/comments', {user: req.user, content, isImage, redirectUrl}

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
  Album.find({where: {id: albumId}, include: [Comment]}).then (album) ->
    render_and_return_comments album.Comments, req, res, album, false
  .catch ->
    res.send {msg: "Couldn't find album."}

exports.get_child_comments = (req, res) ->
  # TODO: Get all comments that are a child of the given comment

exports.post_comment = (req, res) ->
  req.assert('comment', 'Comments must be at least a character long.').notEmpty()
  errors = req.validationErrors()
  if errors
    req.flash 'errors', errors
    return res.redirect '/'

  isImage = req.body.imageId?
  if isImage
    imageId = req.body.imageId
    redirectUrl = '/image/' + imageId
  else
    albumId = req.body.albumId
    redirectUrl = '/album/' + albumId

  error = () ->
    req.flash 'errors', {msg: 'Failed to post comment.'}
    res.redirect redirectUrl

  success = (newComment) ->
    newComment.save().then ->
      req.flash 'success', {msg: 'Comment posted!'}
      res.redirect redirectUrl
    .catch error

  if isImage
    Image.find({where: {image_id: imageId}}).then (image) ->
      # Yay we have the image to set the new comment as.
      newComment = Comment.build
        value: req.body.comment,
        ImageId: image.id,
        UserId: req.user.id
      return success newComment
    .catch error
  else
    Album.find(albumId).then (album) ->
      newComment = Comment.build
        value: req.body.comment,
        AlbumId: album.id,
        UserId: req.user.id
      return success newComment
    .catch error

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
